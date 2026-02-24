# Training Record Chain Design (2026-02-24)

## Goal

在已完成的 `orchestrator -> {chat-casual, assessment, training-advice}` 基础上，新增 `training-record` 直接落库链路，用于把家长自然语言训练反馈结构化写入 `training_sessions`，并保持可审计写回证据。

## Scope

- `orchestrator` 支持 `module=training_record` 路由。
- 新增 Edge Function：`training-record`。
- 保持统一鉴权、权限校验、SSE 输出、`finalize_writeback` 事务外盒回写。
- 新增 live e2e，验证 `training_sessions` + `operation_logs` + `snapshot_refresh_events`。

## Design Decisions

1. 直接落库（无二次确认）
- 以当前你确认的模式执行，先保证闭环可用性和证据链完整。

2. 最小结构化策略
- 训练时长：从用户文本提取“xx分钟”，未提取到时默认 15。
- 成功率：从模型输出提取百分比，映射为 0~1 小数。
- 摘要与结构化载荷写入 `execution_summary` + `ai_structured`。

3. 写回优先级
- `action_name=training_record_create`
- `event_source_table=training_sessions`
- `priority_level=S2`
- `target_snapshot_type=short_term`

## Verification

- 文件契约测试：函数文件与路由关键字存在。
- CI presence 测试：workflow 部署并执行 training-record smoke。
- live e2e：验证训练记录链路写入及清理无残留。
