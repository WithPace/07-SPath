import { authenticate, checkChildAccess, getServiceClient } from "../_shared/auth.ts";
import { callModelLive } from "../_shared/model-router.ts";
import { finalizeWriteback } from "../_shared/finalize.ts";
import { SSE_HEADERS, sseEvent, sseError } from "../_shared/sse.ts";

type TrainingRecordPayload = {
  child_id: string;
  message: string;
  conversation_id: string;
  request_id: string;
  plan_id?: string;
  orchestrator_latency_ms?: number;
};

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
type DomainLevels = Record<string, DomainLevel>;

const DOMAIN_TAGS = ["语言沟通", "社交互动", "认知学习", "感觉运动", "情绪行为", "生活适应"] as const;

const DOMAIN_KEYWORDS: Record<(typeof DOMAIN_TAGS)[number], string[]> = {
  语言沟通: ["语言", "沟通", "表达", "仿说", "口语", "发音", "词汇", "对话"],
  社交互动: ["社交", "互动", "共同注意", "轮流", "眼神", "回应", "同伴", "打招呼"],
  认知学习: ["认知", "注意力", "学习", "记忆", "问题解决", "配对", "指令理解", "分类"],
  感觉运动: ["感觉", "运动", "精细", "粗大", "平衡", "协调", "触觉", "本体"],
  情绪行为: ["情绪", "行为", "哭闹", "发脾气", "冲动", "焦虑", "自我调节", "情绪管理"],
  生活适应: ["生活", "自理", "进食", "如厕", "穿衣", "刷牙", "睡眠", "日常"],
};

function parseDurationMinutes(input: string): number {
  const match = input.match(/(\d{1,3})\s*分钟/);
  if (match && match[1]) {
    const n = Number.parseInt(match[1], 10);
    if (Number.isFinite(n) && n > 0) return n;
  }
  return 15;
}

function parseSuccessRate(text: string): number | null {
  const match = text.match(/(\d{1,3})\s*%/);
  if (!match || !match[1]) return null;
  const n = Number.parseInt(match[1], 10);
  if (!Number.isFinite(n)) return null;
  const clamped = Math.max(0, Math.min(100, n));
  return clamped / 100;
}

function clampInt(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.round(value)));
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

function scoreToLevel(score: number): number {
  return clampInt(Math.ceil(score / 17), 1, 6);
}

function defaultDomainLevel(updatedAt: string): DomainLevel {
  const defaultScore = 45;
  return {
    level: scoreToLevel(defaultScore),
    score: defaultScore,
    trend: "stable",
    sub_items: [],
    score_reason: "初始化画像",
    updated_at: updatedAt,
  };
}

function normalizeSubItems(input: unknown): DomainSubItem[] {
  if (!Array.isArray(input)) return [];
  const normalized: DomainSubItem[] = [];
  for (const item of input) {
    if (!item || typeof item !== "object") continue;
    const record = item as Record<string, unknown>;
    const name = typeof record.name === "string" && record.name.trim() ? record.name.trim() : "";
    if (!name) continue;
    const score = clampInt(toNumberOr(45, record.score), 0, 100);
    normalized.push({ name, score });
    if (normalized.length >= 8) break;
  }
  return normalized;
}

function normalizeDomainLevel(input: unknown, updatedAt: string): DomainLevel {
  const fallback = defaultDomainLevel(updatedAt);
  if (!input || typeof input !== "object") return fallback;
  const record = input as Record<string, unknown>;
  const score = clampInt(toNumberOr(fallback.score, record.score), 0, 100);
  const level = clampInt(toNumberOr(scoreToLevel(score), record.level), 1, 6);
  const trend = normalizeTrend(record.trend);
  const subItems = normalizeSubItems(record.sub_items);
  const scoreReason = typeof record.score_reason === "string" && record.score_reason.trim()
    ? record.score_reason.trim()
    : fallback.score_reason;
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

function normalizeDomainLevels(input: unknown, updatedAt: string): DomainLevels {
  const normalized: DomainLevels = {};
  const inputRecord = input && typeof input === "object" ? input as Record<string, unknown> : {};
  for (const domain of DOMAIN_TAGS) {
    normalized[domain] = normalizeDomainLevel(inputRecord[domain], updatedAt);
  }
  return normalized;
}

function inferDomainTag(text: string): (typeof DOMAIN_TAGS)[number] {
  const normalized = text.toLowerCase();
  for (const domain of DOMAIN_TAGS) {
    const keywords = DOMAIN_KEYWORDS[domain];
    for (const kw of keywords) {
      if (normalized.includes(kw.toLowerCase())) return domain;
    }
  }
  return "认知学习";
}

function inferSubItemName(text: string, domainTag: (typeof DOMAIN_TAGS)[number]): string {
  const normalized = text.toLowerCase();
  if (normalized.includes("共同注意")) return "共同注意";
  if (normalized.includes("仿说")) return "仿说";
  if (normalized.includes("眼神")) return "眼神交流";
  if (normalized.includes("进食")) return "进食";
  if (normalized.includes("如厕")) return "如厕";
  if (normalized.includes("情绪")) return "情绪调节";
  if (normalized.includes("注意力")) return "注意力";
  return `${domainTag}训练`;
}

function calcScoreDelta(successRate: number | null, durationMinutes: number): number {
  const successComponent = successRate === null ? 2 : clampInt((successRate - 0.6) * 20, -6, 8);
  const durationComponent = durationMinutes >= 30 ? 2 : durationMinutes >= 15 ? 1 : 0;
  return clampInt(successComponent + durationComponent, -6, 10);
}

function mergeSubItems(prevItems: DomainSubItem[], itemName: string, nextScore: number): DomainSubItem[] {
  const merged = [...prevItems];
  const idx = merged.findIndex((it) => it.name === itemName);
  if (idx >= 0) {
    merged[idx] = { name: itemName, score: nextScore };
  } else {
    merged.unshift({ name: itemName, score: nextScore });
  }
  return merged.slice(0, 8);
}

function buildOverallSummary(domainTag: string, score: number, trend: DomainTrend): string {
  const trendText = trend === "improving" ? "上升" : trend === "declining" ? "下降" : "稳定";
  return `训练记录累计更新：${domainTag} 领域当前评分 ${score}，趋势${trendText}。`;
}

function buildTrainingRecordFallback(message: string): string {
  const normalized = message.replace(/\s+/g, " ").trim();
  const focus = normalized.length > 24 ? normalized.slice(0, 24) : normalized;
  const topic = focus || "训练记录";
  return `训练记录降级输出：已记录“${topic}”，本次建议按 15 分钟执行并以 60% 完成率作为基线，明日根据执行结果调整难度。`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: SSE_HEADERS });
  }

  let requestId = crypto.randomUUID();
  const startedAt = Date.now();

  try {
    const { user } = await authenticate(req);
    const payload = (await req.json()) as TrainingRecordPayload;
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

    let model = { text: "", modelUsed: "training_record_fallback_rule" };
    try {
      model = await callModelLive([
        { role: "system", content: "你是星途AI训练记录助手，请把用户描述整理为简洁、结构化、可执行的训练记录中文摘要。" },
        { role: "user", content: payload.message },
      ]);
    } catch {
      model = {
        text: buildTrainingRecordFallback(payload.message),
        modelUsed: "training_record_fallback_rule",
      };
    }

    const durationMinutes = parseDurationMinutes(payload.message);
    const successRate = parseSuccessRate(`${payload.message} ${model.text}`);
    const domainTag = inferDomainTag(`${payload.message}\n${model.text}`);
    const subItemName = inferSubItemName(payload.message, domainTag);
    const scoreDelta = calcScoreDelta(successRate, durationMinutes);

    const client = getServiceClient();

    const sessionInsert = await client
      .from("training_sessions")
      .insert({
        child_id: payload.child_id,
        plan_id: payload.plan_id ?? null,
        target_skill: "训练记录",
        execution_summary: model.text,
        prompt_level: "medium",
        success_rate: successRate,
        duration_minutes: durationMinutes,
        notes: payload.message,
        input_type: "text",
        ai_structured: {
          summary: model.text,
          source_message: payload.message,
          model_used: model.modelUsed,
        },
        feedback: {},
        recorded_by: user.id,
        session_date: new Date().toISOString().slice(0, 10),
      })
      .select("id")
      .single();

    if (sessionInsert.error || !sessionInsert.data?.id) {
      throw new Error(`INTERNAL_ERROR: write training session failed: ${sessionInsert.error?.message ?? "unknown"}`);
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
    const nextDomainLevels = normalizeDomainLevels(latestProfile.data?.domain_levels, profileUpdatedAt);
    const prevDomain = nextDomainLevels[domainTag];
    const nextScore = clampInt(prevDomain.score + scoreDelta, 0, 100);
    const nextTrend: DomainTrend = scoreDelta > 1 ? "improving" : scoreDelta < -1 ? "declining" : "stable";

    nextDomainLevels[domainTag] = {
      level: scoreToLevel(nextScore),
      score: nextScore,
      trend: nextTrend,
      sub_items: mergeSubItems(prevDomain.sub_items, subItemName, nextScore),
      score_reason: "训练记录累计更新",
      updated_at: profileUpdatedAt,
    };

    const profileInsert = await client
      .from("children_profiles")
      .insert({
        child_id: payload.child_id,
        version: nextVersion,
        domain_levels: nextDomainLevels,
        overall_summary: buildOverallSummary(domainTag, nextScore, nextTrend),
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
      edge_function: "training-record",
    });

    if (assistantInsert.error) {
      throw new Error(`INTERNAL_ERROR: write assistant message failed: ${assistantInsert.error.message}`);
    }

    const latencyMs = Date.now() - startedAt + (payload.orchestrator_latency_ms ?? 0);
    await finalizeWriteback({
      requestId,
      actorUserId: user.id,
      childId: payload.child_id,
      actionName: "training_record_create",
      affectedTables: ["training_sessions", "children_profiles", "chat_messages", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "children_profiles",
      eventType: "insert",
      priorityLevel: "S2",
      targetSnapshotType: "both",
      payload: {
        training_session_id: sessionInsert.data.id,
        children_profile_id: profileInsert.data.id,
        children_profile_version: profileInsert.data.version,
        domain_tag: domainTag,
        conversation_id: payload.conversation_id,
        plan_id: payload.plan_id ?? null,
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
        training_session_id: sessionInsert.data.id,
      });

    return new Response(body, { status: 200, headers: SSE_HEADERS });
  } catch (err) {
    const body = sseError("INTERNAL_ERROR", err instanceof Error ? err.message : "unknown error", requestId);
    return new Response(body, { status: 500, headers: SSE_HEADERS });
  }
});
