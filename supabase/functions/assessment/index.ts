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

function deriveRiskLevel(text: string): "low" | "medium" | "high" {
  const normalized = text.toLowerCase();
  if (normalized.includes("高风险") || normalized.includes("high risk")) return "high";
  if (normalized.includes("低风险") || normalized.includes("low risk")) return "low";
  return "medium";
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

    const model = await callModelLive([
      { role: "system", content: "你是星途AI评估助手，请输出简洁中文评估结论，包含风险判断和建议。" },
      { role: "user", content: payload.message },
    ]);

    const riskLevel = deriveRiskLevel(model.text);
    const assessmentType = payload.assessment_type?.trim() || "screening";

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
      affectedTables: ["assessments", "snapshot_refresh_events", "operation_logs"],
      eventSourceTable: "assessments",
      eventType: "insert",
      priorityLevel: "S1",
      targetSnapshotType: "both",
      payload: {
        assessment_id: assessmentInsert.data.id,
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
