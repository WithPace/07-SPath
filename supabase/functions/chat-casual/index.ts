import { authenticate, checkChildAccess, getServiceClient } from "../_shared/auth.ts";
import { callModelLive } from "../_shared/model-router.ts";
import { finalizeWriteback } from "../_shared/finalize.ts";
import { SSE_HEADERS, sseEvent, sseError } from "../_shared/sse.ts";

type ChatPayload = {
  child_id: string;
  message: string;
  conversation_id: string;
  request_id: string;
  orchestrator_latency_ms?: number;
};

function buildMemorySummary(modelText: string): string {
  const normalized = modelText.replace(/\s+/g, " ").trim();
  if (!normalized) return "本次对话完成，建议保持日常稳定互动。";
  return normalized.length > 280 ? normalized.slice(0, 280) : normalized;
}

function buildFallbackFocus(message: string): string {
  const trimmed = message.replace(/\s+/g, " ").trim();
  const base = trimmed.length > 24 ? trimmed.slice(0, 24) : trimmed;
  return `日常沟通支持：${base || "亲子互动与情绪安抚"}`;
}

function buildFallbackReply(message: string): string {
  const focus = buildFallbackFocus(message).replace(/^日常沟通支持：/, "");
  return `我已收到你的需求。先围绕“${focus}”做3步：1) 用简短句示范动作；2) 孩子完成后立即正向反馈；3) 记录1次成功与1次困难，稍后我再帮你调整。`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: SSE_HEADERS });
  }

  let requestId: string = crypto.randomUUID();
  const startedAt = Date.now();

  try {
    const { user } = await authenticate(req);
    const payload = (await req.json()) as ChatPayload;
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

    let modelText = "";
    let modelUsed = "chat_fallback_rule";
    try {
      const model = await callModelLive([
        { role: "system", content: "你是星途AI的日常对话助手，请给出简洁、温和、可执行的中文回答。" },
        { role: "user", content: payload.message },
      ]);
      modelText = model.text;
      modelUsed = model.modelUsed;
    } catch {
      modelText = buildFallbackReply(payload.message);
      modelUsed = "chat_fallback_rule";
    }

    const client = getServiceClient();
    const memorySummary = buildMemorySummary(modelText);
    const currentMemory = await client
      .from("children_memory")
      .select("id,current_focus")
      .eq("child_id", payload.child_id)
      .maybeSingle();

    if (currentMemory.error) {
      throw new Error(`INTERNAL_ERROR: load children memory failed: ${currentMemory.error.message}`);
    }

    const memoryUpsert = await client
      .from("children_memory")
      .upsert({
        child_id: payload.child_id,
        current_focus: currentMemory.data?.current_focus || buildFallbackFocus(payload.message),
        last_interaction_summary: memorySummary,
        updated_at: new Date().toISOString(),
      }, { onConflict: "child_id" })
      .select("id")
      .single();

    if (memoryUpsert.error || !memoryUpsert.data?.id) {
      throw new Error(`INTERNAL_ERROR: write children memory failed: ${memoryUpsert.error?.message ?? "unknown"}`);
    }

    const assistantInsert = await client.from("chat_messages").insert({
      conversation_id: payload.conversation_id,
      child_id: payload.child_id,
      user_id: user.id,
      role: "assistant",
      content: modelText,
      model_used: modelUsed,
      edge_function: "chat-casual",
    });

    if (assistantInsert.error) {
      throw new Error(`INTERNAL_ERROR: write assistant message failed: ${assistantInsert.error.message}`);
    }

    const latencyMs = Date.now() - startedAt + (payload.orchestrator_latency_ms ?? 0);

    await finalizeWriteback({
      requestId,
      actorUserId: user.id,
      childId: payload.child_id,
      actionName: "chat_casual_reply",
      affectedTables: ["chat_messages", "children_memory", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "chat_messages",
      eventType: "insert",
      priorityLevel: "S2",
      targetSnapshotType: "both",
      payload: {
        conversation_id: payload.conversation_id,
        children_memory_id: memoryUpsert.data.id,
      },
      dbWriteStatus: "success",
      outboxWriteStatus: "success",
      finalStatus: "completed",
      latencyMs,
    });

    const body =
      sseEvent("stream_start", { request_id: requestId }) +
      sseEvent("delta", { text: modelText }) +
      sseEvent("done", { request_id: requestId, model_used: modelUsed });

    return new Response(body, { status: 200, headers: SSE_HEADERS });
  } catch (err) {
    const body = sseError("INTERNAL_ERROR", err instanceof Error ? err.message : "unknown error", requestId);
    return new Response(body, { status: 500, headers: SSE_HEADERS });
  }
});
