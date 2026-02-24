import { authenticate, checkChildAccess, getServiceClient } from "../_shared/auth.ts";
import { callModelLive } from "../_shared/model-router.ts";
import { finalizeWriteback } from "../_shared/finalize.ts";
import { SSE_HEADERS, sseEvent, sseError } from "../_shared/sse.ts";

type DashboardPayload = {
  child_id: string;
  message: string;
  conversation_id: string;
  request_id: string;
  role?: string;
  orchestrator_latency_ms?: number;
};

type SessionRow = {
  session_date: string | null;
  duration_minutes: number | null;
  success_rate: number | null;
};

function dateKeyUTC(daysAgo: number): string {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() - daysAgo);
  return d.toISOString().slice(0, 10);
}

function normalizeSessionDate(input: string | null): string | null {
  if (!input) return null;
  if (/^\d{4}-\d{2}-\d{2}$/.test(input)) return input;
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(0, 10);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: SSE_HEADERS });
  }

  let requestId = crypto.randomUUID();
  const startedAt = Date.now();

  try {
    const { user } = await authenticate(req);
    const payload = (await req.json()) as DashboardPayload;
    requestId = payload.request_id || requestId;

    if (!payload.child_id || !payload.conversation_id || !payload.message) {
      return new Response(
        sseError("BAD_REQUEST", "child_id/conversation_id/message are required", requestId),
        { status: 400, headers: SSE_HEADERS },
      );
    }

    const role = (payload.role ?? "parent").toLowerCase();
    if (role !== "parent") {
      return new Response(
        sseError("BAD_REQUEST", "dashboard currently supports role=parent only", requestId),
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

    const client = getServiceClient();

    const sinceDate = dateKeyUTC(6);
    const sessionsQuery = await client
      .from("training_sessions")
      .select("session_date,duration_minutes,success_rate")
      .eq("child_id", payload.child_id)
      .eq("recorded_by", user.id)
      .gte("session_date", sinceDate)
      .order("session_date", { ascending: true });

    if (sessionsQuery.error) {
      throw new Error(`INTERNAL_ERROR: read training_sessions failed: ${sessionsQuery.error.message}`);
    }
    const sessions = (sessionsQuery.data ?? []) as SessionRow[];

    const assessmentsQuery = await client
      .from("assessments")
      .select("risk_level,created_at")
      .eq("child_id", payload.child_id)
      .eq("assessed_by", user.id)
      .order("created_at", { ascending: false })
      .limit(3);

    if (assessmentsQuery.error) {
      throw new Error(`INTERNAL_ERROR: read assessments failed: ${assessmentsQuery.error.message}`);
    }

    const activePlansQuery = await client
      .from("training_plans")
      .select("id", { count: "exact", head: true })
      .eq("child_id", payload.child_id)
      .eq("created_by", user.id)
      .eq("status", "active");

    if (activePlansQuery.error) {
      throw new Error(`INTERNAL_ERROR: read training_plans failed: ${activePlansQuery.error.message}`);
    }

    const latestRisk = (assessmentsQuery.data?.[0]?.risk_level ?? "unknown") as string;
    const activePlans = activePlansQuery.count ?? 0;

    const dayMap = new Map<string, { sessions: number; minutes: number }>();
    for (let i = 6; i >= 0; i -= 1) {
      dayMap.set(dateKeyUTC(i), { sessions: 0, minutes: 0 });
    }

    let totalSessions = 0;
    let totalMinutes = 0;
    let successCount = 0;
    let successRateSum = 0;

    for (const row of sessions) {
      const key = normalizeSessionDate(row.session_date);
      if (!key || !dayMap.has(key)) continue;

      const current = dayMap.get(key)!;
      const mins = Number(row.duration_minutes ?? 0);
      current.sessions += 1;
      current.minutes += Number.isFinite(mins) ? mins : 0;
      dayMap.set(key, current);

      totalSessions += 1;
      totalMinutes += Number.isFinite(mins) ? mins : 0;

      if (typeof row.success_rate === "number" && Number.isFinite(row.success_rate)) {
        successRateSum += row.success_rate;
        successCount += 1;
      }
    }

    const trainingDays = Array.from(dayMap.values()).filter((d) => d.sessions > 0).length;
    const avgSuccessRate = successCount > 0 ? Math.round((successRateSum / successCount) * 100) : 0;

    const trendSeries = Array.from(dayMap.entries()).map(([date, v]) => ({
      date,
      sessions: v.sessions,
      minutes: v.minutes,
    }));

    const cards = [
      {
        card_type: "summary_card",
        title: "本周训练概览",
        metrics: [
          { key: "training_days", label: "训练天数", value: trainingDays, unit: "天" },
          { key: "total_sessions", label: "训练次数", value: totalSessions, unit: "次" },
          { key: "total_minutes", label: "训练时长", value: totalMinutes, unit: "分钟" },
          { key: "avg_success_rate", label: "平均成功率", value: avgSuccessRate, unit: "%" },
          { key: "active_plans", label: "活跃方案", value: activePlans, unit: "个" },
        ],
      },
      {
        card_type: "trend_chart",
        title: "近7天训练趋势",
        series: trendSeries,
      },
      {
        card_type: "metric_card",
        title: "最新评估风险",
        risk_level: latestRisk,
      },
    ];

    const insightInput = {
      role,
      latest_risk: latestRisk,
      training_days: trainingDays,
      total_sessions: totalSessions,
      total_minutes: totalMinutes,
      avg_success_rate: avgSuccessRate,
      active_plans: activePlans,
      trend: trendSeries,
      user_query: payload.message,
    };

    const model = await callModelLive([
      { role: "system", content: "你是星途AI家长看板分析助手。请基于给定统计数据输出简洁中文洞察，包含亮点、风险提醒、下一步建议，各1-2句。" },
      { role: "user", content: JSON.stringify(insightInput) },
    ]);

    const assistantInsert = await client.from("chat_messages").insert({
      conversation_id: payload.conversation_id,
      child_id: payload.child_id,
      user_id: user.id,
      role: "assistant",
      content: model.text,
      cards_json: cards,
      model_used: model.modelUsed,
      edge_function: "dashboard",
    });

    if (assistantInsert.error) {
      throw new Error(`INTERNAL_ERROR: write assistant message failed: ${assistantInsert.error.message}`);
    }

    const latencyMs = Date.now() - startedAt + (payload.orchestrator_latency_ms ?? 0);
    await finalizeWriteback({
      requestId,
      actorUserId: user.id,
      childId: payload.child_id,
      actionName: "dashboard_generate",
      affectedTables: ["training_sessions", "assessments", "training_plans", "chat_messages", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "training_sessions",
      eventType: "read",
      priorityLevel: "S3",
      targetSnapshotType: "short_term",
      payload: {
        role: "parent",
        card_count: cards.length,
        conversation_id: payload.conversation_id,
      },
      dbWriteStatus: "success",
      outboxWriteStatus: "success",
      finalStatus: "completed",
      latencyMs,
    });

    const body =
      sseEvent("stream_start", { request_id: requestId }) +
      sseEvent("delta", { text: model.text, cards }) +
      sseEvent("done", {
        request_id: requestId,
        model_used: model.modelUsed,
        role: "parent",
        card_count: cards.length,
      });

    return new Response(body, { status: 200, headers: SSE_HEADERS });
  } catch (err) {
    const body = sseError("INTERNAL_ERROR", err instanceof Error ? err.message : "unknown error", requestId);
    return new Response(body, { status: 500, headers: SSE_HEADERS });
  }
});
