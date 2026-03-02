import { authenticate, checkChildRoleAccess, getServiceClient, normalizeChildRole } from "../_shared/auth.ts";
import { SSE_HEADERS, sseError } from "../_shared/sse.ts";

type OrchestratorPayload = {
  child_id: string;
  message: string;
  conversation_id?: string;
  request_id?: string;
  role?: string;
  module?:
    | "chat_casual"
    | "assessment"
    | "training"
    | "training_advice"
    | "training_record"
    | "dashboard"
    | string;
};

type RouteTarget = {
  functionName: "chat-casual" | "assessment" | "training" | "training-advice" | "training-record" | "dashboard";
  actionName:
    | "chat_casual_reply"
    | "assessment_generate"
    | "training_generate"
    | "training_advice_generate"
    | "training_record_create"
    | "dashboard_generate";
  module: "chat_casual" | "assessment" | "training" | "training_advice" | "training_record" | "dashboard";
};

function getAuthHeader(req: Request): string {
  return req.headers.get("authorization") ?? req.headers.get("Authorization") ?? "";
}

function resolveRoute(moduleInput?: string): RouteTarget {
  const normalized = (moduleInput ?? "chat_casual").toLowerCase().replace(/-/g, "_").trim();

  if (normalized === "chat_casual" || normalized === "chat") {
    return {
      functionName: "chat-casual",
      actionName: "chat_casual_reply",
      module: "chat_casual",
    };
  }

  if (normalized === "assessment") {
    return {
      functionName: "assessment",
      actionName: "assessment_generate",
      module: "assessment",
    };
  }

  if (normalized === "training" || normalized === "train" || normalized === "training_plan") {
    return {
      functionName: "training",
      actionName: "training_generate",
      module: "training",
    };
  }

  if (normalized === "training_advice" || normalized === "trainingadvice") {
    return {
      functionName: "training-advice",
      actionName: "training_advice_generate",
      module: "training_advice",
    };
  }

  if (normalized === "training_record" || normalized === "trainingrecord") {
    return {
      functionName: "training-record",
      actionName: "training_record_create",
      module: "training_record",
    };
  }

  if (normalized === "dashboard" || normalized === "analysis") {
    return {
      functionName: "dashboard",
      actionName: "dashboard_generate",
      module: "dashboard",
    };
  }

  throw new Error("BAD_REQUEST: unsupported module");
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
    const route = resolveRoute(payload.module);

    if (!payload.child_id || !payload.message) {
      return new Response(
        sseError("BAD_REQUEST", "child_id and message are required", requestId),
        { status: 400, headers: SSE_HEADERS },
      );
    }

    const role = normalizeChildRole(payload.role ?? "parent");
    if (!role) {
      return new Response(
        sseError("BAD_REQUEST", "role must be one of parent/doctor/teacher/org_admin", requestId),
        { status: 400, headers: SSE_HEADERS },
      );
    }

    const hasAccess = await checkChildRoleAccess(user.id, payload.child_id, role);
    if (!hasAccess) {
      return new Response(
        sseError("AUTH_FORBIDDEN", "no child access for requested role", requestId),
        { status: 403, headers: SSE_HEADERS },
      );
    }

    const client = getServiceClient();

    // Idempotency: if request_id already logged as completed, short-circuit.
    const existingOp = await client
      .from("operation_logs")
      .select("id")
      .eq("request_id", requestId)
      .eq("action_name", route.actionName)
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

    const fnUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/${route.functionName}`;
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
        role,
        module: route.module,
        orchestrator_latency_ms: Date.now() - startedAt,
      }),
    });

    if (!fnResp.ok || !fnResp.body) {
      const txt = await fnResp.text();
      return new Response(
        sseError("INTERNAL_ERROR", `${route.functionName} forward failed: ${txt || fnResp.status}`, requestId),
        { status: 500, headers: SSE_HEADERS },
      );
    }

    return new Response(fnResp.body, {
      status: 200,
      headers: SSE_HEADERS,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "unknown error";
    const isBadRequest = typeof msg === "string" && msg.startsWith("BAD_REQUEST:");
    return new Response(
      sseError(isBadRequest ? "BAD_REQUEST" : "INTERNAL_ERROR", msg, requestId),
      { status: isBadRequest ? 400 : 500, headers: SSE_HEADERS },
    );
  }
});
