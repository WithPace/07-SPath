# StarPath AI 后端代码审查报告

> 审查日期：2026-02-22
> 审查范围：8 个共享模块 + 4 个角色 Prompt + 12 个业务 Edge Function + 5 个管理后台 Edge Function + 7 个数据库迁移文件
> 审查人：backend-review agent

---

## 一、严重问题（必须修复）

### 1.1 [CRITICAL] `finalize.ts` — Final Writeback 未使用数据库事务

**文件**: `supabase/functions/_shared/finalize.ts:4-57`

设计文档明确要求"所有写入操作必须同事务提交业务数据 + snapshot_refresh_events + operation_logs"，但当前实现是两次独立的 `.insert()` 调用，没有事务包裹。如果第一次写入成功但第二次失败，会导致数据不一致。

```typescript
// 当前：两次独立写入，无事务保证
const { error: eventError } = await client.from("snapshot_refresh_events").insert(...);
const { error: logError } = await client.from("operation_logs").insert(operationLog);
```

**修复建议**: 使用 Supabase 的 `rpc()` 调用一个 PostgreSQL 函数，在函数内用 `BEGIN...COMMIT` 包裹三次写入（业务数据 + outbox + operation_log），或至少使用 `supabase-js` 的事务支持。

---

### 1.2 [CRITICAL] `orchestrator/index.ts:46` — 双重 `req.json()` 消费导致运行时错误

**文件**: `supabase/functions/orchestrator/index.ts:46`

`req.json()` 在第 46 行已被调用一次。Request body 是一个 ReadableStream，只能消费一次。后续代码不会再次调用，但这本身是一个需要注意的模式。

更严重的是 `assessment/index.ts:35`：

**文件**: `supabase/functions/assessment/index.ts:35`

```typescript
// 第 15 行已经调用了 req.json()
const { child_id, action, answers } = await req.json();
// 第 35 行又调用了一次
const { question_index } = await req.json().catch(() => ({ question_index: 0 }));
```

第二次 `req.json()` 会抛出异常（body already consumed），虽然有 `.catch()` 兜底，但 `question_index` 永远拿不到正确值。

**修复建议**: 在函数入口处一次性解构所有字段：
```typescript
const { child_id, action, answers, question_index } = await req.json();
```

---

### 1.3 [CRITICAL] `auth.ts` — 每次调用都创建新的 Supabase Client 实例

**文件**: `supabase/functions/_shared/auth.ts:7-9`

```typescript
export function getServiceClient() {
  return createClient(supabaseUrl, supabaseServiceKey);
}
```

每次调用 `getServiceClient()` 都会创建一个全新的 `SupabaseClient` 实例。在一个请求生命周期内，`orchestrator` 会调用 `authenticate()`（内部调用 `getServiceClient()`）、`checkChildAccess()`（再次调用）、业务逻辑中又调用，导致单个请求创建 3-5 个客户端实例，浪费连接资源。

**修复建议**: 使用模块级单例或请求级缓存：
```typescript
let _serviceClient: ReturnType<typeof createClient> | null = null;
export function getServiceClient() {
  if (!_serviceClient) {
    _serviceClient = createClient(supabaseUrl, supabaseServiceKey);
  }
  return _serviceClient;
}
```

---

### 1.4 [CRITICAL] notifications 表字段名不匹配 — RLS 策略与 Edge Function 冲突

**RLS 策略** (`00005_rls_policies.sql:133-137`):
```sql
CREATE POLICY "notif_select" ON notifications FOR SELECT
  USING (to_user_id = auth.uid());
CREATE POLICY "notif_insert" ON notifications FOR INSERT
  WITH CHECK (from_user_id = auth.uid());
```

**Edge Function** (`collaboration/index.ts:61-70`):
```typescript
const notifications = targets.map((t: any) => ({
  user_id: t.user_id,       // 应该是 to_user_id
  child_id,
  type: action ?? "message",
  title: ...,
  content: fullResponse,
  from_user_id: userId,
  from_role: member.role,    // 表中无此字段
  is_read: false,
}));
```

问题：
1. Edge Function 写入 `user_id` 但表定义的字段是 `to_user_id`，写入会失败
2. `from_role` 字段在 notifications 表中不存在，写入会失败
3. 即使用 service_role_key 绕过 RLS，字段名不匹配仍会导致 PostgreSQL 报错

**修复建议**: 统一字段名为 `to_user_id`，删除 `from_role` 字段或在表中添加该列。

---

### 1.5 [CRITICAL] `snapshot-refresh/index.ts` — 缺少认证，任何人可触发快照刷新

**文件**: `supabase/functions/snapshot-refresh/index.ts:6-84`

此函数没有调用 `authenticate()`，也没有验证请求来源是否为 Database Webhook。任何知道 URL 的人都可以发送 POST 请求触发快照刷新，可能导致：
- 资源耗尽（大量并发刷新）
- 数据篡改（伪造 event payload）

**修复建议**: 添加 Webhook 密钥验证：
```typescript
const webhookSecret = req.headers.get("x-webhook-secret");
if (webhookSecret !== Deno.env.get("WEBHOOK_SECRET")) {
  return errorResponse("AUTH_INVALID", "Unauthorized", 401);
}
```

---

### 1.6 [CRITICAL] 管理后台 5 个 Edge Function 全部缺少认证

以下函数均未验证调用者身份：

| 文件 | 问题 |
|------|------|
| `admin-quality-review/index.ts` | 无认证，任何人可触发质量评审 |
| `admin-daily-digest/index.ts` | 无认证，任何人可触发日报生成 |
| `admin-churn-predict/index.ts` | 无认证，可获取用户 PII 数据 |
| `admin-prompt-advisor/index.ts` | 仅 OPTIONS 处理，无 JWT 验证 |
| `admin-alert-analysis/index.ts` | 仅 OPTIONS 处理，无 JWT 验证 |

虽然部分函数设计为 pg_cron 触发，但 Supabase Edge Functions 的 HTTP 端点是公开的。必须添加认证机制（service_role_key 验证或 admin JWT 验证）。

**修复建议**: 统一添加 cron/webhook 认证中间件：
```typescript
const authHeader = req.headers.get("Authorization");
if (authHeader !== `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`) {
  return new Response("Unauthorized", { status: 401 });
}
```

---

### 1.7 [CRITICAL] `admin-quality-review/index.ts` — N+1 查询性能灾难

**文件**: `supabase/functions/admin-quality-review/index.ts:42-88`

```typescript
for (const msg of messages) {  // 最多 200 条
  // 每条消息都发起一次 DB 查询
  const { data: context } = await serviceClient.from("chat_messages")...
  // 每条消息都发起一次 AI 模型调用
  await callModelStream("dashboard", [...], {...});
  // 每条消息都发起一次 DB 写入
  await serviceClient.from("admin_audit_logs").insert({...});
}
```

200 条消息 = 200 次 DB 查询 + 200 次 AI 调用 + 200 次 DB 写入 = 600 次串行 I/O。按每次 AI 调用 2-5 秒计算，总耗时 400-1000 秒，远超 Edge Function 的执行时间限制（通常 60 秒）。

**修复建议**:
1. 批量查询上下文消息（一次 JOIN 查询）
2. 使用 `Promise.all` 并发处理（控制并发数，如 5 个一批）
3. 批量写入 audit_logs
4. 考虑分页处理，每次只处理 20-30 条

---

### 1.8 [CRITICAL] `admin-churn-predict/index.ts` — 用户 PII 数据直接发送给 AI 模型

**文件**: `supabase/functions/admin-churn-predict/index.ts:41-53`

```typescript
const { data: users } = await serviceClient
  .from("users")
  .select("id, nickname, role, vip_level, created_at, last_active_at")
  .in("id", atRiskIds);

await callModelStream("chat-casual", [
  { role: "user", content: JSON.stringify(users) },  // 用户数据直接发给 AI
], ...);
```

将用户 ID、昵称等 PII 数据直接发送给第三方 AI 模型（Doubao/Kimi），存在数据隐私合规风险。

**修复建议**: 对用户数据脱敏后再发送，用序号替代真实 ID，移除昵称等可识别信息。

---

## 二、警告问题（建议修复）

### 2.1 [WARNING] `model-router.ts` — 缺少 `life-record`、`weekly-report`、`analysis-report`、`periodic-report` 的模型配置

**文件**: `supabase/functions/_shared/model-router.ts:10-67`

`MODEL_CONFIGS` 中只定义了 8 个场景的配置，但实际有 12+ 个 Edge Function 需要调用模型。缺失的场景会 fallback 到 `chat-casual` 配置（第 85 行），这意味着：
- `weekly-report` 和 `analysis-report` 本应使用 Kimi 2.5，实际使用了 Doubao
- `periodic-report` 同理
- `life-record` 的结构化提取使用了 `chat-casual` 的高 temperature (0.7)，不适合 JSON 提取

**修复建议**: 为所有场景补充显式配置，特别是需要低 temperature 的结构化提取场景。

---

### 2.2 [WARNING] `orchestrator/index.ts:157-163` — `Deno.readTextFile` 读取 Prompt 文件路径可能不正确

**文件**: `supabase/functions/orchestrator/index.ts:157-163`

```typescript
const promptPath = new URL(`../_shared/prompts/${role}.md`, import.meta.url);
let rolePrompt = "";
try {
  rolePrompt = await Deno.readTextFile(promptPath);
} catch {
  rolePrompt = "你是一位专业的AI助手。";
}
```

在 Supabase Edge Functions 的 Deno Deploy 环境中，`import.meta.url` 可能不指向文件系统路径，而是 `https://` URL。`Deno.readTextFile()` 不支持 HTTP URL。部署后此代码会静默失败，所有角色都会使用 fallback prompt。

同样的问题存在于：`behavior-crisis/index.ts:30`、`collaboration/index.ts:43`、`training-advice/index.ts:30`

**修复建议**: 将 Prompt 内容直接内联为 TypeScript 常量，或使用 `import` 语句导入：
```typescript
import parentPrompt from "../_shared/prompts/parent.md" with { type: "text" };
```

---

### 2.3 [WARNING] `orchestrator/index.ts:91-106` — 意图识别使用流式调用浪费资源

**文件**: `supabase/functions/orchestrator/index.ts:91-106`

意图识别只需要一个简短的 JSON 响应（如 `{"intent":"chat_casual"}`），但使用了 `callModelStream` 流式接口。流式调用有额外的 SSE 解析开销，且 `maxTokens: 200` 的短响应不需要流式传输。

**修复建议**: 为意图识别添加非流式调用方法 `callModelSync()`，直接返回完整响应。

---

### 2.4 [WARNING] `orchestrator/index.ts:175-185` — 聊天历史加载顺序问题

**文件**: `supabase/functions/orchestrator/index.ts:175-185`

```typescript
const { data: recentMessages } = await serviceClient
  .from("chat_messages")
  .select("role, content")
  .eq("conversation_id", convId)
  .order("created_at", { ascending: false })
  .limit(20);

const chatHistory = (recentMessages ?? []).reverse()...
```

当前用户消息已在第 73 行保存到数据库，所以这里查询出的 20 条消息会包含刚保存的用户消息。然后在第 202-205 行又作为 `chatHistory` 的一部分发送给模型，导致用户消息被重复发送。

**修复建议**: 查询时排除刚保存的消息，或在保存用户消息之前查询历史。

---

### 2.5 [WARNING] `dashboard/index.ts` 和 `weekly-report/index.ts` — 缺少 Final Writeback

**文件**: `supabase/functions/dashboard/index.ts`、`supabase/functions/weekly-report/index.ts`、`supabase/functions/analysis-report/index.ts`

这三个函数是只读查询 + AI 生成，没有数据库写入操作，因此没有调用 `finalizeWrite()`。但根据设计文档，所有 Edge Function 调用都应记录 `operation_logs`。

**修复建议**: 即使是只读操作，也应写入 operation_log 用于审计和性能监控。

---

### 2.6 [WARNING] `stream.ts` — SSE 流在异步闭包中的错误无法传播

**文件**: 所有使用 `(async () => { ... })()` 模式的 Edge Function

```typescript
const response = sse.getResponse();
(async () => {
  // 如果这里抛出未捕获的异常...
  sse.sendStart();
  const context = await getFullContext(child_id); // 可能抛异常
  // ...
})();
return response; // response 已经返回给客户端
```

如果异步闭包内部抛出未捕获的异常（如 `getFullContext` 失败），客户端会收到一个永远不会关闭的 SSE 流（没有 `done` 或 `error` 事件），导致客户端永久挂起。

**修复建议**: 在异步闭包内添加顶层 try-catch：
```typescript
(async () => {
  try {
    sse.sendStart();
    // ... 业务逻辑
  } catch (err) {
    sse.sendError("INTERNAL_ERROR", (err as Error).message);
  }
})();
```

---

### 2.7 [WARNING] `periodic-report/index.ts:78` — HTML 注入风险

**文件**: `supabase/functions/periodic-report/index.ts:78`

```typescript
${reportContent.replace(/\n/g, "<br>")}
```

AI 生成的 `reportContent` 直接插入 HTML，没有转义。如果 AI 输出包含 `<script>` 标签或其他 HTML，会导致 XSS 漏洞。虽然报告主要用于 PDF 下载，但如果通过浏览器直接访问 `file_url`，存在安全风险。

**修复建议**: 对 AI 输出进行 HTML 转义后再插入。

---

### 2.8 [WARNING] `periodic-report/index.ts:87` — Storage 公开 URL 泄露风险

**文件**: `supabase/functions/periodic-report/index.ts:87`

```typescript
const { data: urlData } = serviceClient.storage.from("periodic-reports").getPublicUrl(fileName);
```

使用 `getPublicUrl` 意味着任何知道 URL 的人都可以访问报告。儿童发展报告包含敏感医疗信息，不应公开访问。

**修复建议**: 使用 `createSignedUrl` 生成有时效的签名 URL，或配置 Storage bucket 为私有。

---

### 2.9 [WARNING] `cors.ts` — CORS 配置过于宽松

**文件**: `supabase/functions/_shared/cors.ts:1-6`

```typescript
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  ...
};
```

`Access-Control-Allow-Origin: *` 允许任何域名的请求。生产环境应限制为前端应用的域名。

**修复建议**: 从环境变量读取允许的域名列表：
```typescript
"Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGIN") ?? "https://your-app.com"
```

---

### 2.10 [WARNING] 数据库迁移 — `children_medical` 缺少 `child_id` 唯一约束

**文件**: `supabase/migrations/00001_base_tables.sql:33-49`

`children_memory` 表有 `UNIQUE` 约束（第 54 行），但 `children_medical` 没有。这意味着一个孩子可以有多条医疗记录，但 `snapshot.ts:72` 使用 `.single()` 查询，多条记录会导致查询失败。

**修复建议**: 添加 `UNIQUE(child_id)` 约束，或修改查询为 `.limit(1)` 并按时间排序。

---

### 2.11 [WARNING] 数据库迁移 — `teaching_schedules` 和 `organizations`/`org_members` 表缺失

**文件**: 所有迁移文件

CLAUDE.md 中提到的以下表在迁移文件中不存在：
- `teaching_schedules`（训练域）
- `organizations`（机构域）
- `org_members`（机构域）

这些表在设计文档中被列为必需表，但未创建。

**修复建议**: 补充缺失表的迁移文件。

---

### 2.12 [WARNING] `reports` 表缺少 `created_by` 字段

**文件**: `supabase/migrations/00003_assessment_training_records.sql:93-105`

`reports` 表定义中没有 `created_by` 字段，但 `periodic-report/index.ts:97` 尝试写入该字段：
```typescript
created_by: userId,
```

这会导致写入失败（PostgreSQL 会忽略未知列或报错，取决于 Supabase 客户端配置）。

**修复建议**: 在 reports 表中添加 `created_by UUID REFERENCES users(id)` 字段。

---

### 2.13 [WARNING] `admin_audit_logs` — `admin_id` 外键约束与系统写入冲突

**文件**: `supabase/migrations/006_admin_tables.sql:29`

```sql
admin_id UUID NOT NULL REFERENCES admin_users(id),
```

`admin-quality-review/index.ts:71` 使用硬编码的零 UUID 作为系统用户：
```typescript
admin_id: "00000000-0000-0000-0000-000000000000", // system
```

如果 `admin_users` 表中没有这个 UUID 的记录，外键约束会导致写入失败。

**修复建议**: 在迁移中预插入一条系统用户记录，或将 `admin_id` 改为可空。

---

## 三、跨文件共性问题汇总

### 3.1 异步闭包缺少顶层错误处理（影响 10 个文件）

以下 Edge Function 均使用 `(async () => { ... })()` 模式启动后台流式处理，但闭包内部没有顶层 try-catch。任何未捕获的异常都会导致 SSE 流永远不关闭，客户端挂起。

受影响文件：
- `orchestrator/index.ts`
- `assessment/index.ts`
- `dashboard/index.ts`
- `training-record/index.ts`
- `training-advice/index.ts`
- `life-record/index.ts`
- `behavior-crisis/index.ts`
- `weekly-report/index.ts`
- `analysis-report/index.ts`
- `collaboration/index.ts`

---

### 3.2 `onError` 回调处理不一致（影响 12 个文件）

各 Edge Function 对 `callModelStream` 的 `onError` 回调处理方式不统一：

| 处理方式 | 文件 |
|---------|------|
| `sse.sendError(...)` | dashboard, assessment, behavior-crisis, collaboration, training-advice |
| `() => {}` 空函数（静默吞掉错误） | weekly-report, analysis-report, periodic-report, training-record(第二次调用), life-record |
| 5 个管理后台函数 | 全部使用空函数 |

静默吞掉错误会导致：AI 调用失败时客户端收到空响应或不完整响应，无法排查问题。

**修复建议**: 统一错误处理策略，至少记录日志。

---

### 3.3 `Deno.readTextFile` 读取 Prompt 在部署环境可能失败（影响 4 个文件）

受影响文件：`orchestrator/index.ts`、`behavior-crisis/index.ts`、`collaboration/index.ts`、`training-advice/index.ts`

详见 2.2 节。

---

### 3.4 Service Client 重复创建（影响所有文件）

几乎每个 Edge Function 都在多个位置调用 `getServiceClient()`，每次创建新实例。详见 1.3 节。

---

### 3.5 `any` 类型滥用（影响所有文件）

大量使用 `as any` 类型断言和 `any` 类型参数，削弱了 TypeScript 的类型安全保障：

```typescript
// snapshot-refresh/index.ts:86
async function refreshShortTerm(client: any, childId: string)

// dashboard/index.ts:65
Object.entries(domainLevels).map(([name, data]: [string, any]) => ...)

// behavior-crisis/index.ts:47
(context.longTerm as any)?.memory?.nickname
```

**修复建议**: 在 `types.ts` 中定义完整的数据库行类型，使用 Supabase 的类型生成工具 `supabase gen types typescript`。

---

## 四、SQL 迁移专项审查

### 4.1 迁移文件命名不一致

- 前 5 个文件使用 5 位数字前缀：`00001_`、`00002_`...
- 后 2 个文件使用 3 位数字前缀：`006_`、`007_`

Supabase CLI 按字典序执行迁移，`006_` 会排在 `00001_` 之前，导致执行顺序错误（admin 表在基础表之前创建，外键引用失败）。

**修复建议**: 统一为 `00006_admin_tables.sql` 和 `00007_admin_rls.sql`。

---

### 4.2 `update_updated_at()` 函数重复定义

- `00001_base_tables.sql:80-86` 定义了 `update_updated_at()`
- `006_admin_tables.sql:167-170` 又定义了 `update_admin_updated_at()`（功能完全相同）

**修复建议**: 管理后台表复用 `update_updated_at()`，删除 `update_admin_updated_at()`。

---

### 4.3 RLS 策略中 `snapshot_refresh_events`、`operation_logs`、`snapshot_refresh_logs` 未启用 RLS

这三张系统运行表在 `00005_rls_policies.sql` 中未启用 RLS，也未在 `007_admin_rls.sql` 中处理。虽然 Edge Function 使用 service_role_key 绕过 RLS，但如果有人获取了 anon_key，可以直接读写这些表。

**修复建议**: 启用 RLS 并添加策略，仅允许 service_role 和 admin 访问。

---

### 4.4 `admin_prompts` 表缺少 `(role, version)` 唯一约束

同一角色可能存在多个相同版本号的 Prompt 记录，导致数据混乱。

**修复建议**: 添加 `UNIQUE(role, version)` 约束。

---

### 4.5 `notifications` 表 RLS 策略与 `collaboration` Edge Function 的字段名不匹配

详见 1.4 节。RLS 策略引用 `to_user_id` 和 `from_user_id`，但 Edge Function 写入 `user_id`。

---

## 五、修复优先级排序

### P0 — 立即修复（阻塞部署）

| # | 问题 | 影响 |
|---|------|------|
| 1 | 1.4 notifications 字段名不匹配 | 协作功能完全不可用 |
| 2 | 1.2 assessment 双重 req.json() | M-CHAT 评估 next_question 功能失效 |
| 3 | 1.5 + 1.6 缺少认证的 6 个 Edge Function | 严重安全漏洞 |
| 4 | 2.12 reports 表缺少 created_by 字段 | 周期报告写入失败 |
| 5 | 2.13 admin_audit_logs 零 UUID 外键失败 | 质量评审写入失败 |
| 6 | 4.1 迁移文件命名导致执行顺序错误 | 数据库初始化失败 |

### P1 — 尽快修复（影响可靠性）

| # | 问题 | 影响 |
|---|------|------|
| 7 | 1.1 Final Writeback 无事务保证 | 数据一致性风险 |
| 8 | 3.1 异步闭包缺少错误处理 | 客户端可能永久挂起 |
| 9 | 1.7 质量评审 N+1 查询 | 函数超时，功能不可用 |
| 10 | 2.2 Deno.readTextFile 部署失败 | 所有角色 Prompt 失效 |
| 11 | 2.4 聊天历史重复消息 | AI 回复质量下降 |
| 12 | 2.1 模型配置缺失 | 多个场景使用错误模型 |

### P2 — 计划修复（影响质量和安全）

| # | 问题 | 影响 |
|---|------|------|
| 13 | 1.3 Service Client 重复创建 | 资源浪费 |
| 14 | 1.8 PII 数据发送给 AI | 隐私合规风险 |
| 15 | 2.7 HTML 注入风险 | XSS 安全风险 |
| 16 | 2.8 Storage 公开 URL | 敏感数据泄露 |
| 17 | 2.9 CORS 过于宽松 | 安全风险 |
| 18 | 3.2 onError 处理不一致 | 排查困难 |
| 19 | 3.5 any 类型滥用 | 类型安全缺失 |

### P3 — 后续优化

| # | 问题 | 影响 |
|---|------|------|
| 20 | 2.3 意图识别使用流式调用 | 性能浪费 |
| 21 | 2.5 只读函数缺少 operation_log | 审计不完整 |
| 22 | 2.10 children_medical 缺少唯一约束 | 潜在查询失败 |
| 23 | 2.11 缺失表（teaching_schedules 等） | 功能不完整 |
| 24 | 4.2 触发器函数重复定义 | 代码冗余 |
| 25 | 4.3 系统表未启用 RLS | 安全隐患 |
| 26 | 4.4 admin_prompts 缺少唯一约束 | 数据完整性 |

---

## 六、总结

本次审查共发现 **8 个严重问题** 和 **18 个警告问题**，其中 6 个问题会直接阻塞部署。

最关键的三类问题：
1. **安全问题**：6 个 Edge Function 缺少认证、CORS 过于宽松、Storage 公开访问、PII 泄露
2. **数据一致性**：字段名不匹配导致写入失败、Final Writeback 无事务保证
3. **可靠性问题**：异步闭包无错误处理、N+1 查询超时、Prompt 加载在部署环境失败

建议按 P0 → P1 → P2 → P3 的优先级逐步修复，P0 问题必须在部署前全部解决。
