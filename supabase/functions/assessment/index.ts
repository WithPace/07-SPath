import { authenticate, checkChildAccess, getServiceClient } from "../_shared/auth.ts";
import { callModelLive } from "../_shared/model-router.ts";
import { finalizeWriteback } from "../_shared/finalize.ts";
import { SSE_HEADERS, sseEvent, sseError } from "../_shared/sse.ts";

type AssessmentPayload = {
  child_id: string;
  message: string;
  conversation_id: string;
  request_id: string;
  assessment_type?: string;
  orchestrator_latency_ms?: number;
};

type DomainTag = "语言沟通" | "社交互动" | "认知学习" | "感觉运动" | "情绪行为" | "生活适应";
type DomainTrend = "improving" | "stable" | "declining";
type DomainSubItem = {
  name: string;
  score: number;
};
type DomainLevel = {
  level: number;
  score: number;
  trend: DomainTrend;
  sub_items: DomainSubItem[];
  score_reason: string;
  updated_at: string;
};

const DOMAIN_TAGS: DomainTag[] = ["语言沟通", "社交互动", "认知学习", "感觉运动", "情绪行为", "生活适应"];

const DOMAIN_KEYWORDS: Record<DomainTag, string[]> = {
  语言沟通: ["语言", "沟通", "表达", "仿说", "口语", "发音", "词汇", "对话"],
  社交互动: ["社交", "互动", "共同注意", "轮流", "眼神", "回应", "同伴", "打招呼"],
  认知学习: ["认知", "注意力", "学习", "记忆", "问题解决", "配对", "分类", "理解"],
  感觉运动: ["感觉", "运动", "精细", "粗大", "平衡", "协调", "触觉", "本体"],
  情绪行为: ["情绪", "行为", "哭闹", "发脾气", "冲动", "焦虑", "调节", "激惹"],
  生活适应: ["生活", "自理", "进食", "如厕", "穿衣", "刷牙", "睡眠", "作息"],
};

const DOMAIN_OFFSETS: Record<DomainTag, number> = {
  语言沟通: 0,
  社交互动: -2,
  认知学习: 2,
  感觉运动: 3,
  情绪行为: -3,
  生活适应: 1,
};

const RISK_BASE_SCORE: Record<"low" | "medium" | "high", number> = {
  low: 72,
  medium: 54,
  high: 36,
};

function deriveRiskLevel(text: string): "low" | "medium" | "high" {
  const normalized = text.toLowerCase();
  if (normalized.includes("高风险") || normalized.includes("high risk")) return "high";
  if (normalized.includes("低风险") || normalized.includes("low risk")) return "low";
  return "medium";
}

function clampInt(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.round(value)));
}

function scoreToLevel(score: number): number {
  return clampInt(Math.ceil(score / 17), 1, 6);
}

function toNumberOr(defaultValue: number, input: unknown): number {
  if (typeof input === "number" && Number.isFinite(input)) return input;
  if (typeof input === "string") {
    const parsed = Number.parseFloat(input);
    if (Number.isFinite(parsed)) return parsed;
  }
  return defaultValue;
}

function normalizeTrend(input: unknown): DomainTrend {
  if (input === "improving" || input === "stable" || input === "declining") {
    return input;
  }
  return "stable";
}

function normalizeSubItems(input: unknown): DomainSubItem[] {
  if (!Array.isArray(input)) return [];
  const normalized: DomainSubItem[] = [];
  for (const item of input) {
    if (!item || typeof item !== "object") continue;
    const record = item as Record<string, unknown>;
    const name = typeof record.name === "string" && record.name.trim() ? record.name.trim() : "";
    if (!name) continue;
    const score = clampInt(toNumberOr(50, record.score), 0, 100);
    normalized.push({ name, score });
    if (normalized.length >= 8) break;
  }
  return normalized;
}

function normalizeDomainLevel(input: unknown, fallbackScore: number, updatedAt: string): DomainLevel {
  if (!input || typeof input !== "object") {
    return {
      level: scoreToLevel(fallbackScore),
      score: fallbackScore,
      trend: "stable",
      sub_items: [],
      score_reason: "初始化画像",
      updated_at: updatedAt,
    };
  }

  const record = input as Record<string, unknown>;
  const score = clampInt(toNumberOr(fallbackScore, record.score), 0, 100);
  const level = clampInt(toNumberOr(scoreToLevel(score), record.level), 1, 6);
  const trend = normalizeTrend(record.trend);
  const subItems = normalizeSubItems(record.sub_items);
  const scoreReason = typeof record.score_reason === "string" && record.score_reason.trim()
    ? record.score_reason.trim()
    : "初始化画像";
  const normalizedUpdatedAt = typeof record.updated_at === "string" && record.updated_at.trim()
    ? record.updated_at
    : updatedAt;

  return {
    level,
    score,
    trend,
    sub_items: subItems,
    score_reason: scoreReason,
    updated_at: normalizedUpdatedAt,
  };
}

function inferDomainTag(text: string): DomainTag {
  const normalized = text.toLowerCase();
  for (const domain of DOMAIN_TAGS) {
    for (const keyword of DOMAIN_KEYWORDS[domain]) {
      if (normalized.includes(keyword.toLowerCase())) return domain;
    }
  }
  return "社交互动";
}

function buildAssessmentSummary(riskLevel: "low" | "medium" | "high", focusDomain: DomainTag): string {
  const riskText = riskLevel === "low" ? "低风险" : riskLevel === "high" ? "高风险" : "中风险";
  return `评估结果更新：本次评估判定为${riskText}，重点关注 ${focusDomain} 领域，已生成新画像版本。`;
}

function buildAssessmentFallback(message: string): string {
  const normalized = message.replace(/\s+/g, " ").trim();
  const focus = normalized.length > 24 ? normalized.slice(0, 24) : normalized;
  const topic = focus || "家庭训练执行";
  return `评估降级输出：当前按中风险处理。请先围绕“${topic}”执行 3 步：1) 分解为单步指令；2) 每次成功立即强化；3) 记录触发因素并在 24 小时内复盘。`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: SSE_HEADERS });
  }

  let requestId = crypto.randomUUID();
  const startedAt = Date.now();

  try {
    const { user } = await authenticate(req);
    const payload = (await req.json()) as AssessmentPayload;
    requestId = payload.request_id || requestId;

    if (!payload.child_id || !payload.conversation_id || !payload.message) {
      return new Response(
        sseError("BAD_REQUEST", "child_id/conversation_id/message are required", requestId),
        { status: 400, headers: SSE_HEADERS },
      );
    }

    const hasAccess = await checkChildAccess(user.id, payload.child_id);
    if (!hasAccess) {
      return new Response(
        sseError("AUTH_FORBIDDEN", "no child access", requestId),
        { status: 403, headers: SSE_HEADERS },
      );
    }

    let model = { text: "", modelUsed: "assessment_fallback_rule" };
    try {
      model = await callModelLive([
        { role: "system", content: "你是星途AI评估助手，请输出简洁中文评估结论，包含风险判断和建议。" },
        { role: "user", content: payload.message },
      ]);
    } catch {
      model = {
        text: buildAssessmentFallback(payload.message),
        modelUsed: "assessment_fallback_rule",
      };
    }

    const riskLevel = deriveRiskLevel(model.text);
    const assessmentType = payload.assessment_type?.trim() || "screening";
    const focusDomain = inferDomainTag(`${payload.message}\n${model.text}`);

    const client = getServiceClient();

    const assessmentInsert = await client
      .from("assessments")
      .insert({
        child_id: payload.child_id,
        type: assessmentType,
        result: {
          summary: model.text,
          model_used: model.modelUsed,
          source_message: payload.message,
        },
        risk_level: riskLevel,
        recommendations: {
          summary: model.text,
        },
        assessed_by: user.id,
      })
      .select("id")
      .single();

    if (assessmentInsert.error || !assessmentInsert.data?.id) {
      throw new Error(`INTERNAL_ERROR: write assessment failed: ${assessmentInsert.error?.message ?? "unknown"}`);
    }

    const latestProfile = await client
      .from("children_profiles")
      .select("version,domain_levels")
      .eq("child_id", payload.child_id)
      .order("version", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (latestProfile.error) {
      throw new Error(`INTERNAL_ERROR: load latest profile failed: ${latestProfile.error.message}`);
    }

    const profileUpdatedAt = new Date().toISOString();
    const nextVersion = (latestProfile.data?.version ?? 0) + 1;
    const baseScore = RISK_BASE_SCORE[riskLevel];
    const sourceLevels = latestProfile.data?.domain_levels && typeof latestProfile.data.domain_levels === "object"
      ? latestProfile.data.domain_levels as Record<string, unknown>
      : {};

    const nextDomainLevels: Record<string, DomainLevel> = {};
    for (const domain of DOMAIN_TAGS) {
      const targetScore = clampInt(baseScore + DOMAIN_OFFSETS[domain] + (domain === focusDomain ? 4 : 0), 0, 100);
      const prev = normalizeDomainLevel(sourceLevels[domain], targetScore, profileUpdatedAt);
      const nextScore = clampInt(prev.score * 0.4 + targetScore * 0.6, 0, 100);
      const diff = nextScore - prev.score;
      const trend: DomainTrend = diff > 1 ? "improving" : diff < -1 ? "declining" : "stable";

      const nextSubItems = prev.sub_items.length > 0
        ? prev.sub_items
        : [{ name: `${domain}评估`, score: nextScore }];

      nextDomainLevels[domain] = {
        level: scoreToLevel(nextScore),
        score: nextScore,
        trend,
        sub_items: nextSubItems,
        score_reason: "评估结果更新",
        updated_at: profileUpdatedAt,
      };
    }

    const profileInsert = await client
      .from("children_profiles")
      .insert({
        child_id: payload.child_id,
        version: nextVersion,
        domain_levels: nextDomainLevels,
        overall_summary: buildAssessmentSummary(riskLevel, focusDomain),
        assessed_by: user.id,
        assessed_at: profileUpdatedAt,
      })
      .select("id,version")
      .single();

    if (profileInsert.error || !profileInsert.data?.id) {
      throw new Error(`INTERNAL_ERROR: write profile version failed: ${profileInsert.error?.message ?? "unknown"}`);
    }

    const assistantInsert = await client.from("chat_messages").insert({
      conversation_id: payload.conversation_id,
      child_id: payload.child_id,
      user_id: user.id,
      role: "assistant",
      content: model.text,
      model_used: model.modelUsed,
      edge_function: "assessment",
    });

    if (assistantInsert.error) {
      throw new Error(`INTERNAL_ERROR: write assistant message failed: ${assistantInsert.error.message}`);
    }

    const latencyMs = Date.now() - startedAt + (payload.orchestrator_latency_ms ?? 0);
    await finalizeWriteback({
      requestId,
      actorUserId: user.id,
      childId: payload.child_id,
      actionName: "assessment_generate",
      affectedTables: ["assessments", "children_profiles", "chat_messages", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "children_profiles",
      eventType: "insert",
      priorityLevel: "S1",
      targetSnapshotType: "both",
      payload: {
        assessment_id: assessmentInsert.data.id,
        children_profile_id: profileInsert.data.id,
        children_profile_version: profileInsert.data.version,
        domain_tag: focusDomain,
        conversation_id: payload.conversation_id,
      },
      dbWriteStatus: "success",
      outboxWriteStatus: "success",
      finalStatus: "completed",
      latencyMs,
    });

    const body =
      sseEvent("stream_start", { request_id: requestId }) +
      sseEvent("delta", { text: model.text }) +
      sseEvent("done", {
        request_id: requestId,
        model_used: model.modelUsed,
        assessment_id: assessmentInsert.data.id,
      });

    return new Response(body, { status: 200, headers: SSE_HEADERS });
  } catch (err) {
    const body = sseError("INTERNAL_ERROR", err instanceof Error ? err.message : "unknown error", requestId);
    return new Response(body, { status: 500, headers: SSE_HEADERS });
  }
});
