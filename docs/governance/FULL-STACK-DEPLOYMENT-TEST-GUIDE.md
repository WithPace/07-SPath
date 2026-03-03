# Full-Stack Deployment and Test Guide

## Scope

This guide is the execution checklist for:

- backend/governance repo: `07-SPath`
- user app repo: `starpath-frontend`
- admin web repo: `starpath-admin-web`

It is aligned with Harness Engineering governance gates and uses official Supabase (no Docker DB path).

## 1. Prerequisites

1. Toolchain:
   - `git`
   - `node` (recommend LTS 20+)
   - `pnpm` (`corepack enable`)
   - `supabase` CLI (`2.75.0` expected by repo check script)
2. Supabase:
   - official project created
   - `SUPABASE_PROJECT_REF` available
   - `SUPABASE_DB_PASSWORD` available
   - logged in via `supabase login`
3. All three repos are checked out under the same parent directory.

## 2. Backend Deploy Chain (07-SPath)

### 2.1 Required `.env`

In `07-SPath/.env`, ensure:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_DB_PASSWORD`
- `SUPABASE_PROJECT_REF`
- `DOUBAO_API_KEY`
- `KIMI_API_KEY`

### 2.2 Run Strict Go-Live Sequence

```bash
cd /Users/neal/Documents/07-项目2026beta/07-SPath
bash scripts/db/preflight.sh
bash scripts/ci/deploy_functions.sh
bash scripts/ci/release_go_live.sh
```

Expected result:

- phase sign-off gates pass
- 7 Edge Functions deploy pass
- `final_gate` + governance tests pass
- release record auto-updates in `docs/governance/PHASE-2-RELEASE-RECORD.md`

## 3. User App (starpath-frontend) Packaging and Deploy

### 3.1 Required env

Create `starpath-frontend/.env.local` (or copy `.env.example`) with:

- `NEXT_PUBLIC_API_BASE_URL`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### 3.2 Local verification + package

```bash
cd /Users/neal/Documents/07-项目2026beta/starpath-frontend
pnpm install
bash scripts/ci/frontend_final_gate.sh
```

Gate includes:

- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`
- `pnpm build`
- `pnpm playwright test`

### 3.3 Local start for testing

```bash
pnpm start
```

Default URL: `http://localhost:3000`

### 3.4 Production deploy options

Option A (Vercel CLI):

```bash
pnpm dlx vercel --prod
```

Option B (self-hosted Next.js):

```bash
pnpm build
PORT=3000 pnpm start
```

## 4. Admin Web (starpath-admin-web) Packaging and Deploy

### 4.1 Env status

Current admin web implementation does not enforce runtime env keys in code.  
If future API integration is added, create `.env.local` and document required keys first.

### 4.2 Local verification + package

```bash
cd /Users/neal/Documents/07-项目2026beta/starpath-admin-web
pnpm install
bash scripts/ci/admin_web_final_gate.sh
```

Gate includes:

- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`
- `pnpm build`
- `pnpm playwright test`

### 4.3 Local start for testing

```bash
PORT=3001 pnpm start
```

Recommended URL: `http://localhost:3001`

### 4.4 Production deploy options

Option A (Vercel CLI):

```bash
pnpm dlx vercel --prod
```

Option B (self-hosted Next.js):

```bash
pnpm build
PORT=3001 pnpm start
```

## 5. Integrated Release Verification Order

Run in this order:

1. `07-SPath`: `bash scripts/ci/release_go_live.sh`
2. `starpath-frontend`: `bash scripts/ci/frontend_final_gate.sh`
3. `starpath-admin-web`: `bash scripts/ci/admin_web_final_gate.sh`

If all pass, the phase baseline is deployable for testing.

## 6. Rollback References

- Backend go-live and rollback drills: `docs/governance/DEPLOY-TEST-GO-LIVE-RUNBOOK.md`
- Backend remote publish flow: `docs/governance/REMOTE-PUBLISH-RUNBOOK.md`
- Frontend rollback: `../starpath-frontend/docs/governance/FRONTEND-ROLLBACK-RUNBOOK.md`
- Admin web rollback: `../starpath-admin-web/docs/governance/ADMIN-WEB-ROLLBACK-RUNBOOK.md`
