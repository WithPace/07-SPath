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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: SSE_HEADERS });
  }

  let requestId = crypto.randomUUID();
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

    const model = await callModelLive([
      { role: "system", content: "你是星途AI的日常对话助手，请给出简洁、温和、可执行的中文回答。" },
      { role: "user", content: payload.message },
    ]);

    const client = getServiceClient();
    const assistantInsert = await client.from("chat_messages").insert({
      conversation_id: payload.conversation_id,
      child_id: payload.child_id,
      user_id: user.id,
      role: "assistant",
      content: model.text,
      model_used: model.modelUsed,
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
      affectedTables: ["chat_messages", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "chat_messages",
      eventType: "insert",
      priorityLevel: "S2",
      targetSnapshotType: "short_term",
      payload: { conversation_id: payload.conversation_id },
      dbWriteStatus: "success",
      outboxWriteStatus: "success",
      finalStatus: "completed",
      latencyMs,
    });

    const body =
      sseEvent("stream_start", { request_id: requestId }) +
      sseEvent("delta", { text: model.text }) +
      sseEvent("done", { request_id: requestId, model_used: model.modelUsed });

    return new Response(body, { status: 200, headers: SSE_HEADERS });
  } catch (err) {
    const body = sseError("INTERNAL_ERROR", err instanceof Error ? err.message : "unknown error", requestId);
    return new Response(body, { status: 500, headers: SSE_HEADERS });
  }
});
