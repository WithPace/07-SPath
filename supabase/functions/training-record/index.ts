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

    const model = await callModelLive([
      { role: "system", content: "你是星途AI训练记录助手，请把用户描述整理为简洁、结构化、可执行的训练记录中文摘要。" },
      { role: "user", content: payload.message },
    ]);

    const durationMinutes = parseDurationMinutes(payload.message);
    const successRate = parseSuccessRate(model.text);

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
      affectedTables: ["training_sessions", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "training_sessions",
      eventType: "insert",
      priorityLevel: "S2",
      targetSnapshotType: "short_term",
      payload: {
        training_session_id: sessionInsert.data.id,
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
