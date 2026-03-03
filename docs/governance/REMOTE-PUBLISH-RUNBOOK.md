# Remote Publish Runbook

## Purpose

This runbook defines the final remote publishing checklist after local main-branch integration and strict gates are complete.

## Scope

- backend/governance repo: `07-SPath`
- frontend repo: `starpath-frontend`
- admin web repo: `starpath-admin-web`

## Required Inputs

1. unified release tag exists in all three repos (example: `release-main-2026-03-03`)
2. all repos are on `main`
3. working trees are clean
4. strict gates already passed:
   - backend `bash scripts/ci/release_go_live.sh`
   - frontend `bash scripts/ci/frontend_final_gate.sh`
   - admin web `bash scripts/ci/admin_web_final_gate.sh`

## Precheck (No Push)

This command only validates readiness and prints push commands. It does not execute any push action.

```bash
RELEASE_TAG=release-main-2026-03-03 REQUIRE_ORIGIN=0 bash scripts/ci/prepare_remote_publish.sh
```

For strict remote readiness (must have origin in all repos):

```bash
RELEASE_TAG=release-main-2026-03-03 REQUIRE_ORIGIN=1 bash scripts/ci/prepare_remote_publish.sh
```

## Push Execution (Manual)

After precheck passes with `REQUIRE_ORIGIN=1`, run the printed commands manually:

```bash
git -C "./" push origin main
git -C "./" push origin release-main-2026-03-03

git -C "../starpath-frontend" push origin main
git -C "../starpath-frontend" push origin release-main-2026-03-03

git -C "../starpath-admin-web" push origin main
git -C "../starpath-admin-web" push origin release-main-2026-03-03
```

## Post-Push Traceability

1. verify tags and branches are visible on remote
2. append remote publish timestamp and operator to governance verification ledger
3. if any repo push fails, stop and resolve before promoting deployment status
