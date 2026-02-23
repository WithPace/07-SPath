import { getServiceClient } from "./auth.ts";

export type FinalizeInput = {
  requestId: string;
  actorUserId: string;
  childId: string;
  actionName: string;
  affectedTables: string[];
  eventSourceTable: string;
  eventType: string;
  priorityLevel: "S1" | "S2" | "S3";
  targetSnapshotType: "short_term" | "long_term" | "both";
  payload: Record<string, unknown>;
  dbWriteStatus: "success" | "failed";
  outboxWriteStatus: "success" | "failed";
  finalStatus: "completed" | "failed" | "compensated";
  latencyMs?: number;
  errorCode?: string;
  errorMessage?: string;
};

export async function finalizeWriteback(input: FinalizeInput): Promise<void> {
  const client = getServiceClient();
  const { error } = await client.rpc("finalize_writeback", {
    p_request_id: input.requestId,
    p_actor_user_id: input.actorUserId,
    p_child_id: input.childId,
    p_action_name: input.actionName,
    p_affected_tables: input.affectedTables,
    p_event_source_table: input.eventSourceTable,
    p_event_type: input.eventType,
    p_priority_level: input.priorityLevel,
    p_target_snapshot_type: input.targetSnapshotType,
    p_payload: input.payload,
    p_db_write_status: input.dbWriteStatus,
    p_outbox_write_status: input.outboxWriteStatus,
    p_final_status: input.finalStatus,
    p_latency_ms: input.latencyMs ?? null,
    p_error_code: input.errorCode ?? null,
    p_error_message: input.errorMessage ?? null,
  });

  if (error) {
    throw new Error(`WRITE_PARTIAL: finalize rpc failed (${error.message})`);
  }
}
