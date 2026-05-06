# Operational checklist: DB-02 cloud parity rollout

Use this immediately after merging DB-02 code, before treating sync as “production safe”.

Date context: created 2026-05-07.

## 0) Repository / CI (no Supabase access required)

- [x] All DB-02 migrations present under `supabase/migrations/` (including `20260506201000_notification_preferences_and_support_contacts.sql`).
- [x] `swift test` passes on current `main` (59 tests) — run locally after each relevant change.
- [ ] Install [Supabase CLI](https://supabase.com/docs/guides/cli) if you use `supabase db push` / linked projects; this environment had no `supabase` binary.

## 1) Supabase (all target environments) — **owner**

- [ ] Migrations applied through **`20260506201000_notification_preferences_and_support_contacts.sql`** (and any prior required files) on **staging**, then **production**.
- [ ] Confirm tables exist: `public.notification_preferences`, `public.support_contacts`; **`public.achievements`** and **`public.sobriety_records`** unchanged but RLS still enabled.
- [ ] Smoke query as an authenticated test user (SQL editor or REST with user JWT): `select` own row from each table; expect RLS to allow only `auth.uid()` rows.
- [ ] PostgREST: verify upsert works for achievements (unique `(user_id, type)`); types use `milestone_<days>` (e.g. `milestone_7`).

## 2) Secrets and config

- [ ] iOS **`Secrets.xcconfig`** (or CI secrets) still valid; no accidental commit of keys.
- [ ] Supabase **anon** key rotation only if exposure suspected; update app/CI after rotation.

## 3) App verification matrix (manual)

Run on a **real device** where possible; at least one pass on simulator.

| Scenario | Expected |
|----------|----------|
| Fresh install → sign in → open Profile | Notification prefs + SOS contact match server after sync; no permanent error banner. |
| Change prefs + SOS on device A | Rows updated in Supabase; reopen app → same values. |
| Sign in on device B (clean app data) | Prefs/contact/history/milestones converge after main tabs load (may need one navigation). |
| Airplane mode: change pref → online | Local saves; when online, cloud catches up (or dismissible error, then retry). |
| Stats after relapse on another device | Periods/milestones consistent with `sobriety_records` + `achievements` after hydrate. |

## 4) Monitoring and support

- [ ] Decide where sync failures are observed (logs only vs crash/analytics). Today the app shows **in-app banners**; ensure someone monitors beta feedback for “stuck orange bars”.
- [ ] Document **owner** for “sync broken” triage for the current beta window.

## 5) Rollback posture

- [ ] If a migration must be reverted: **do not** drop tables with user data without backup; prefer fixing forward (RLS/policy bugs).
- [ ] If app build is bad: use existing TestFlight rollback notes (`ios/TESTFLIGHT-ROLLBACK.md`).

## Completion record

- Completed by:
- Environment(s) verified (staging/prod):
- Date (UTC):
