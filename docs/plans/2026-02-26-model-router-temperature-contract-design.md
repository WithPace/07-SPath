# Model Router Temperature Contract Design

## Context

- `_shared/model-router.ts` routes requests to Kimi/Doubao and accepts `ModelCallOptions.temperature`.
- Doubao path already respects `options.temperature ?? 0.4`.
- Kimi path currently hardcodes `temperature = 1`, ignoring caller-provided temperature.

## Problem

- Callers cannot tune Kimi behavior through `ModelCallOptions.temperature`.
- This creates provider behavior drift and weakens predictable generation controls.
- Without a contract, this can regress silently again.

## Options

### Option A: Keep Kimi fixed at temperature 1

Trade-offs:
- Pros: no change.
- Cons: inconsistent API contract across providers; ignores caller intent.

### Option B (Selected): Honor options.temperature in Kimi path

- Change Kimi path to:
  - `const temperature = options.temperature ?? 1;`
- Add static contract gate to enforce:
  - Kimi path reads `options.temperature`.
  - Doubao path keeps existing `options.temperature ?? 0.4`.

Trade-offs:
- Pros: consistent, minimal, backwards-compatible default behavior.
- Cons: tiny behavior change for callers passing explicit temperature with Kimi.

### Option C: Remove temperature from options API

Trade-offs:
- Pros: simpler interface.
- Cons: breaks existing caller expectations and flexibility.

## Chosen Design

- Implement Option B with a small code fix plus static contract test:
  - `tests/functions/test_model_router_temperature_contract.sh`
- Keep change scoped and verified by full gate.
