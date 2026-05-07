# Yandex Cloud Migration Plan

## Goal

Replace Supabase-based auth and database with Yandex Cloud architecture while preserving existing app behavior and data integrity.

## Target Architecture

- **Auth API:** custom auth service (email/password + refresh token) deployed in Yandex Serverless Containers (or Cloud Functions).
- **DB:** Yandex Managed Service for PostgreSQL.
- **App API:** REST API layer in Yandex Serverless Containers/Functions.
- **Storage:** Yandex Object Storage for files/assets.
- **Secrets:** Yandex Lockbox.
- **Network/Security:** VPC, security groups, TLS, least-privilege IAM service accounts.

## Fixed Decisions

- Supabase architecture decision (`D-002`) is deprecated.
- Yandex Cloud architecture decision (`D-017`) is accepted.

## Step-by-step Implementation

### 1) Prepare Yandex Cloud foundation

1. Create folder/environment (dev/stage/prod).
2. Create VPC + subnets + security groups.
3. Create service accounts:
   - `sl-api-sa` (API runtime),
   - `sl-migrate-sa` (one-time migration),
   - `sl-ci-sa` (CI deploy).
4. Create Lockbox secrets:
   - `PG_HOST`, `PG_PORT`, `PG_DB`, `PG_USER`, `PG_PASSWORD`,
   - `JWT_SIGNING_KEY`, `JWT_ISSUER`, `JWT_AUDIENCE`,
   - `OBJECT_STORAGE_ACCESS_KEY`, `OBJECT_STORAGE_SECRET_KEY`.

### 2) Provision PostgreSQL

1. Create Managed PostgreSQL cluster (version compatible with existing schema).
2. Create DB and role for app runtime.
3. Enable SSL required connections.
4. Apply existing schema/migrations:
   - replay SQL migrations from `supabase/migrations/` in order,
   - validate indexes/constraints/triggers.
5. Add migration tracking table (if absent) to avoid reapplying scripts.

### 3) Build Auth service (replacement for Supabase Auth)

1. Implement endpoints:
   - `POST /auth/signup`,
   - `POST /auth/signin`,
   - `POST /auth/refresh`,
   - `POST /auth/signout` (token invalidation/rotation strategy).
2. Issue JWT access token + refresh token with explicit TTL.
3. Hash passwords using Argon2id (recommended) or bcrypt.
4. Add rate limits + brute-force protections.
5. Add email confirmation/reset flows (if required by product policy).

### 4) Build App API (replacement for PostgREST/RPC)

1. Implement endpoints matching current app behaviors:
   - user profile upsert/load,
   - sobriety records load/sync,
   - achievements load/upsert,
   - notification preferences + support contacts,
   - AI conversation history load/save,
   - community pulse check-in + aggregate.
2. Enforce ownership in API layer (`token.user_id == resource.user_id`).
3. Return stable JSON contracts to minimize iOS changes.

### 5) Update iOS app integration

1. Introduce a new backend wiring (parallel to current `AuthWiring`) for Yandex API base URL + auth config.
2. Replace Supabase-specific services with backend adapters while keeping app-level state objects unchanged where possible.
3. Update auth flow:
   - sign-in/sign-up hits new auth API,
   - session persistence stores new JWT/refresh tokens.
4. Update cloud sync services to call new endpoints.
5. Keep local fallback behavior unchanged.

### 6) Data migration from Supabase to Yandex PostgreSQL

1. Export Supabase data (per table, deterministic order).
2. Transform to target schema if needed (UUID/date formats, enums, JSON fields).
3. Import into Yandex PostgreSQL.
4. Validate:
   - row counts,
   - checksums/sample hashes,
   - referential integrity.
5. Freeze write windows for final delta migration during cutover.

### 7) Observability and operations

1. Add structured logs in API/auth services.
2. Add metrics/alerts:
   - auth success/error rates,
   - p95 latency,
   - DB errors,
   - token refresh failures.
3. Define incident runbooks and rollback criteria.

### 8) Staged rollout

1. Deploy to **stage** and run full QA smoke/regression.
2. Enable dual-run canary:
   - read from new backend for internal users,
   - keep fallback/rollback toggle.
3. Cut over production traffic gradually.
4. Monitor for 48h with strict alerting.
5. Decommission Supabase usage only after stability window.

## Required Repo Changes Checklist

- [ ] Add `YandexAuthService` and `YandexBackendService` adapters.
- [ ] Replace Supabase endpoint wiring in iOS `AppRootState`.
- [ ] Add migration SQL compatibility notes for PostgreSQL managed cluster.
- [ ] Add deployment scripts/workflows for Yandex Cloud.
- [ ] Add runbook + rollback doc for Yandex cutover.

## Verification Checklist

- [ ] Existing users can sign in with migrated credentials.
- [ ] Onboarding/profile persists across app restarts.
- [ ] Sobriety history, achievements, notifications sync correctly.
- [ ] Community pulse works in cloud and local fallback modes.
- [ ] No P0/P1 regressions in auth, Home, Chat, SOS, Profile flows.

