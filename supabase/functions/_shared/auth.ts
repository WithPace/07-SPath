import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2";

let _serviceClient: SupabaseClient | null = null;

export const CHILD_ROLES = ["parent", "doctor", "teacher", "org_admin"] as const;
export type ChildRole = (typeof CHILD_ROLES)[number];

function mustEnv(name: string): string {
  const v = Deno.env.get(name);
  if (!v) {
    throw new Error(`missing env: ${name}`);
  }
  return v;
}

export function getServiceClient(): SupabaseClient {
  if (_serviceClient) return _serviceClient;
  _serviceClient = createClient(mustEnv("SUPABASE_URL"), mustEnv("SUPABASE_SERVICE_ROLE_KEY"));
  return _serviceClient;
}

export async function authenticate(req: Request): Promise<{ user: User; token: string }> {
  const authHeader = req.headers.get("authorization") ?? req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    throw new Error("AUTH_INVALID: missing bearer token");
  }

  const client = getServiceClient();
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) {
    throw new Error("AUTH_INVALID: token verification failed");
  }

  return { user: data.user, token };
}

export async function checkChildAccess(userId: string, childId: string): Promise<boolean> {
  const client = getServiceClient();

  const owner = await client
    .from("children")
    .select("id")
    .eq("id", childId)
    .eq("created_by", userId)
    .maybeSingle();

  if (owner.data?.id) return true;

  const team = await client
    .from("care_teams")
    .select("id")
    .eq("child_id", childId)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();

  return Boolean(team.data?.id);
}

export function normalizeChildRole(raw?: string | null): ChildRole | null {
  const normalized = (raw ?? "parent").toLowerCase().replace(/-/g, "_").trim();
  if (CHILD_ROLES.includes(normalized as ChildRole)) {
    return normalized as ChildRole;
  }
  return null;
}

export async function checkChildRoleAccess(userId: string, childId: string, role: ChildRole): Promise<boolean> {
  const client = getServiceClient();

  if (role === "parent") {
    const owner = await client
      .from("children")
      .select("id")
      .eq("id", childId)
      .eq("created_by", userId)
      .maybeSingle();
    if (owner.data?.id) return true;
  }

  let query = client
    .from("care_teams")
    .select("id")
    .eq("child_id", childId)
    .eq("user_id", userId)
    .eq("status", "active");

  if (role === "org_admin") {
    query = query.in("role", ["org_admin", "org-admin"]);
  } else {
    query = query.eq("role", role);
  }

  const team = await query.maybeSingle();
  return Boolean(team.data?.id);
}
