import { authenticate, checkChildAccess, getServiceClient } from "../_shared/auth.ts";
import { callModelLive } from "../_shared/model-router.ts";
import { finalizeWriteback } from "../_shared/finalize.ts";
import { SSE_HEADERS, sseEvent, sseError } from "../_shared/sse.ts";

type TrainingPayload = {
  child_id: string;
  message: string;
  conversation_id: string;
  request_id: string;
  orchestrator_latency_ms?: number;
};

function buildPlanTitle(message: string): string {
  const datePart = new Date().toISOString().slice(0, 10);
  const trimmed = message.trim();
  const base = trimmed.length > 20 ? trimmed.slice(0, 20) : trimmed;
  return `${datePart} 训练计划 - ${base || "个性化训练"}`;
}

function buildCurrentFocus(title: string, modelText: string): string {
  const summary = modelText.replace(/\s+/g, " ").trim();
  const concise = summary.length > 48 ? summary.slice(0, 48) : summary;
  return `${title}｜${concise || "家庭训练执行重点"}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: SSE_HEADERS });
  }

  let requestId = crypto.randomUUID();
  const startedAt = Date.now();

  try {
    const { user } = await authenticate(req);
    const payload = (await req.json()) as TrainingPayload;
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
      { role: "system", content: "你是星途AI训练助手，请输出结构化、可执行、温和的中文训练计划建议。" },
      { role: "user", content: payload.message },
    ]);

    const client = getServiceClient();
    const title = buildPlanTitle(payload.message);

    const planInsert = await client
      .from("training_plans")
      .insert({
        child_id: payload.child_id,
        title,
        goals: {
          summary: model.text.slice(0, 280),
        },
        strategies: {
          advice: model.text,
        },
        schedule: {
          cadence: "daily",
          suggested_duration_minutes: 15,
        },
        difficulty_level: "medium",
        status: "active",
        created_by: user.id,
      })
      .select("id")
      .single();

    if (planInsert.error || !planInsert.data?.id) {
      throw new Error(`INTERNAL_ERROR: write training plan failed: ${planInsert.error?.message ?? "unknown"}`);
    }

    const currentFocus = buildCurrentFocus(title, model.text);
    const memoryUpsert = await client
      .from("children_memory")
      .upsert({
        child_id: payload.child_id,
        current_focus: currentFocus,
        last_interaction_summary: model.text.slice(0, 280),
        updated_at: new Date().toISOString(),
      }, { onConflict: "child_id" })
      .select("id,current_focus")
      .single();

    if (memoryUpsert.error || !memoryUpsert.data?.id) {
      throw new Error(`INTERNAL_ERROR: write children memory failed: ${memoryUpsert.error?.message ?? "unknown"}`);
    }

    const assistantInsert = await client.from("chat_messages").insert({
      conversation_id: payload.conversation_id,
      child_id: payload.child_id,
      user_id: user.id,
      role: "assistant",
      content: model.text,
      model_used: model.modelUsed,
      edge_function: "training",
    });

    if (assistantInsert.error) {
      throw new Error(`INTERNAL_ERROR: write assistant message failed: ${assistantInsert.error.message}`);
    }

    const latencyMs = Date.now() - startedAt + (payload.orchestrator_latency_ms ?? 0);
    await finalizeWriteback({
      requestId,
      actorUserId: user.id,
      childId: payload.child_id,
      actionName: "training_generate",
      affectedTables: ["training_plans", "children_memory", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "training_plans",
      eventType: "insert",
      priorityLevel: "S2",
      targetSnapshotType: "both",
      payload: {
        training_plan_id: planInsert.data.id,
        children_memory_id: memoryUpsert.data.id,
        current_focus: memoryUpsert.data.current_focus,
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
        training_plan_id: planInsert.data.id,
      });

    return new Response(body, { status: 200, headers: SSE_HEADERS });
  } catch (err) {
    const body = sseError("INTERNAL_ERROR", err instanceof Error ? err.message : "unknown error", requestId);
    return new Response(body, { status: 500, headers: SSE_HEADERS });
  }
});
