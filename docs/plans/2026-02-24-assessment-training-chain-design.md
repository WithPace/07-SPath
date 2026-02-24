# Assessment Training Chain Design (2026-02-24)

## Goal

在现有 `orchestrator -> chat-casual` 链路基础上，扩展出可执行的 `assessment -> training` 业务链，支持真实模型调用、真实数据库写回、可审计证据与可复现验证。

## Scope

- 扩展 `orchestrator` 路由能力，支持多模块分发。
- 新增 Edge Functions：
  - `assessment`（写入 `assessments`）
  - `training-advice`（写入 `training_plans`）
- 保持统一认证、权限校验、事务外盒回写（`finalize_writeback`）和 SSE 输出协议。
- 增补 live e2e 用例，验证新增链路副作用和日志证据。

## Constraints

- 不新增/修改数据库表结构（沿用 `20260223170000_rebuild_all.sql`）。
- 向后兼容现有聊天链路与既有测试。
- 继续使用真实 Supabase + 真实模型，不引入 mock。

## Routing Strategy

`orchestrator` 新增可选字段 `module`：

- `chat_casual`（默认）
- `assessment`
- `training_advice`

若未显式传入 `module`，默认走 `chat_casual`，确保现有客户端兼容。

## Writeback Strategy

- `assessment`:
  - 领域写入：`assessments`
  - 日志动作：`assessment_generate`
  - `affected_tables`: `["assessments", "snapshot_refresh_events", "operation_logs"]`
  - `target_snapshot_type`: `both`
  - `priority_level`: `S1`
- `training-advice`:
  - 领域写入：`training_plans`
  - 日志动作：`training_advice_generate`
  - `affected_tables`: `["training_plans", "snapshot_refresh_events", "operation_logs"]`
  - `target_snapshot_type`: `short_term`
  - `priority_level`: `S2`

## Verification

- 文件契约测试：新增函数文件与关键钩子存在性。
- live e2e：新增 `orchestrator -> assessment -> training-advice` 真实链路测试，断言：
  - `assessments` 写入
  - `training_plans` 写入
  - `operation_logs` 对应 action_name 写入
  - `snapshot_refresh_events` 写入
- CI workflow 同步部署新增函数并执行全量门禁脚本。
