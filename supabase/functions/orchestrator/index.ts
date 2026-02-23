import { authenticate, checkChildAccess, getServiceClient } from "../_shared/auth.ts";
import { SSE_HEADERS, sseError } from "../_shared/sse.ts";

type OrchestratorPayload = {
  child_id: string;
  message: string;
  conversation_id?: string;
  request_id?: string;
};

function getAuthHeader(req: Request): string {
  return req.headers.get("authorization") ?? req.headers.get("Authorization") ?? "";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: SSE_HEADERS });
  }

  const startedAt = Date.now();
  let requestId = crypto.randomUUID();

  try {
    const { user } = await authenticate(req);
    const payload = (await req.json()) as OrchestratorPayload;

    requestId = payload.request_id?.trim() || requestId;

    if (!payload.child_id || !payload.message) {
      return new Response(
        sseError("BAD_REQUEST", "child_id and message are required", requestId),
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

    // Idempotency: if request_id already logged as completed, short-circuit.
    const existingOp = await client
      .from("operation_logs")
      .select("id")
      .eq("request_id", requestId)
      .eq("action_name", "chat_casual_reply")
      .eq("final_status", "completed")
      .limit(1)
      .maybeSingle();

    if (existingOp.data?.id) {
      return new Response("event: done\ndata: {\"request_id\":\"" + requestId + "\",\"idempotent\":true}\n\n", {
        headers: SSE_HEADERS,
      });
    }

    let conversationId = payload.conversation_id;
    if (!conversationId) {
      const created = await client
        .from("conversations")
        .insert({
          child_id: payload.child_id,
          user_id: user.id,
          title: "新对话",
          last_message_at: new Date().toISOString(),
          message_count: 0,
          is_deleted: false,
        })
        .select("id")
        .single();

      if (created.error || !created.data?.id) {
        throw new Error(`INTERNAL_ERROR: create conversation failed: ${created.error?.message ?? "unknown"}`);
      }
      conversationId = created.data.id;
    }

    const userInsert = await client.from("chat_messages").insert({
      conversation_id: conversationId,
      child_id: payload.child_id,
      user_id: user.id,
      role: "user",
      content: payload.message,
      edge_function: "orchestrator",
    });

    if (userInsert.error) {
      throw new Error(`INTERNAL_ERROR: write user message failed: ${userInsert.error.message}`);
    }

    const fnUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/chat-casual`;
    const fnResp = await fetch(fnUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: getAuthHeader(req),
      },
      body: JSON.stringify({
        child_id: payload.child_id,
        message: payload.message,
        conversation_id: conversationId,
        request_id: requestId,
        orchestrator_latency_ms: Date.now() - startedAt,
      }),
    });

    if (!fnResp.ok || !fnResp.body) {
      const txt = await fnResp.text();
      return new Response(
        sseError("INTERNAL_ERROR", `chat-casual forward failed: ${txt || fnResp.status}`, requestId),
        { status: 500, headers: SSE_HEADERS },
      );
    }

    return new Response(fnResp.body, {
      status: 200,
      headers: SSE_HEADERS,
    });
  } catch (err) {
    return new Response(
      sseError("INTERNAL_ERROR", err instanceof Error ? err.message : "unknown error", requestId),
      { status: 500, headers: SSE_HEADERS },
    );
  }
});
