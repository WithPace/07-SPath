# StarPath 业务执行链路（审议后重建）设计文档

**Date:** 2026-02-23  
**Status:** Approved  
**Scope:** Supabase 真实环境 + 真实模型 + 破坏式全量重建 + `orchestrator -> chat-casual` 最小闭环

## 1. 重建前数据审议基线（冻结口径）

### 1.1 全量范围

按 `docs/01-PRD-产品需求文档.md` 与 `docs/04-数据结构化设计文档.md` 执行全量重建：

- 业务域：17 张表
- 对话域：2 张表（`conversations`, `chat_messages`）
- 管理后台域：9 张表
- 系统运行域：3 张表（`snapshot_refresh_events`, `operation_logs`, `snapshot_refresh_logs`）

合计 31 张表。

### 1.2 重建前补充项（审议结论）

#### P0（本轮必须完成）

1. DDL 冻结清单（表/字段/约束/索引/RLS）
2. 破坏式重建前备份（结构与关键数据快照）
3. Transactional Outbox 同事务约束（主写入 + outbox + operation log）
4. 鉴权基线（含 webhook/cron 入口）
5. `notifications` 字段统一为 `from_user_id` / `to_user_id`
6. `request_id` 全链路幂等
7. `conversations` 与 `chat_messages` 一致性维护

#### P1（紧随其后）

8. 模型调用 PII 最小化与脱敏策略
9. RLS 验收脚本（多角色 SQL 级验证）
10. 重建后自动门禁（schema/index/RLS/smoke）

## 2. 迁移编排（Supabase CLI，破坏式）

### 2.1 执行顺序

1. `preflight`：环境变量、项目链接、当前库备份校验
2. 审议冻结：产出 `schema-freeze` 作为 SQL 单一真源
3. 迁移生成：`drop + recreate + constraints + indexes + RLS + triggers`
4. `supabase db push` 执行重建
5. 重建验收：结构、权限、E2E、幂等、失败路径
6. 证据输出：记录命令、结果、时间戳、失败项

### 2.2 失败处理

- 重建失败即停止，不做隐式重试
- 使用 preflight 备份恢复
- 修正冻结规格后再执行下一轮 `db push`

## 3. 数据模型与权限关键决议（SQL 前置规格）

1. 主键统一 `uuid`，`child_snapshots` 为复合主键 `(child_id, snapshot_type)`
2. 关键唯一约束：`care_teams(user_id, child_id, role)`、`children_memory(child_id)`、`admin_users.email`、`coupons.code`
3. 对话域固定：`conversations`（会话头）+ `chat_messages`（消息体）
4. 系统运行域固定：`snapshot_refresh_events` + `operation_logs` + `snapshot_refresh_logs`
5. `notifications` 严禁 `user_id/from_role` 歧义字段
6. `children_profiles.domain_levels` 使用 v2.3 丰富 JSON 结构
7. 业务/管理后台表均启用并验证 RLS
8. 所有写入类函数执行 Transactional Outbox
9. `request_id` 全链路透传并用于幂等追踪
10. 用 SQL 断言验证表、约束、索引、RLS 与关键链路

## 4. 最小业务执行链路设计：`orchestrator -> chat-casual`

### 4.1 orchestrator

- 输入：`message`, `child_id`, `conversation_id?`, `request_id?`
- JWT 鉴权并提取 `user_id/role`
- 幂等检查（按 `request_id`）
- 无会话则创建 `conversations`
- 写入用户消息到 `chat_messages(role='user')`
- 最小阶段固定路由到 `chat-casual`

### 4.2 chat-casual

- 权限检查：`care_teams` + RLS
- 上下文读取：优先 `child_snapshots`
- 真实模型调用：Doubao/Kimi（由 `.env` 配置）
- 产出文本（可扩展 cards）

### 4.3 同事务收尾写入

在单事务中完成：

1. assistant 消息写入 `chat_messages`
2. outbox 事件写入 `snapshot_refresh_events`
3. 审计写入 `operation_logs`
4. 更新 `conversations.last_message_at/message_count`

### 4.4 SSE 返回协议

- `stream_start` -> `delta` (多次) -> `done`
- 错误走 `error`（含 `error_code` 与 `request_id`）

## 5. 测试与验收设计

1. 数据库重建验收：31 表、约束、索引、RLS 启用与策略存在
2. RLS 角色验收：`parent/doctor/teacher/org_admin/admin` SQL 级测试
3. E2E 链路验收：orchestrator 调用后验证 `chat_messages`、`operation_logs`、`snapshot_refresh_events` 与 `conversations` 更新
4. 幂等与失败验收：重复 `request_id` 不重复写；失败路径写入审计并返回 SSE error
5. Go/No-Go：全部通过才进入下一业务函数建设

## 6. 里程碑与交付物

### 6.1 里程碑

- M1 审议冻结（含 P0/P1 清单）
- M2 全量重建（Supabase CLI）
- M3 最小链路打通（真实鉴权 + 真实模型 + 同事务收尾）
- M4 自动验收门禁（结构/RLS/E2E/幂等）

### 6.2 交付物

1. Supabase 迁移文件（全量重建）
2. RLS policy、触发器、事务化收尾实现
3. `orchestrator` 与 `chat-casual` 最小实现
4. 验收脚本与验证报告

## 7. 风险说明

- 破坏式重建会清空现有库对象与数据，必须先做备份并确认恢复路径。
- 文档存在历史漂移风险，冻结口径后不得绕过审议直接改 DDL。
- 真实模型调用会触发成本与数据合规风险，需在实现阶段加脱敏与请求追踪。
