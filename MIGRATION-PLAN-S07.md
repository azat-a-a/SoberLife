# SoberLife Supabase migration plan (S07)

Date: 2026-05-06
Status: Draft for implementation planning

## 1) Current state audit

### Already in Supabase (and used by app)
- `public.users`:
  - profile basics (`name`)
  - sobriety baseline (`sobriety_start_date`, `daily_alcohol_cost`)
- `public.sobriety_records`:
  - period timeline (current + past periods)
  - used by `SobrietySupabaseSync` on onboarding sync and relapse sync
- `public.ai_conversations`:
  - cloud chat transcripts when user has valid JWT
- RLS:
  - owner-based policies are enabled (`auth.uid()` checks)
- Profile bootstrap:
  - trigger + RPC (`ensure_user_profile`) keep `public.users` aligned with `auth.users`

### Still local-only on device
- Notification preferences (`UserDefaultsNotificationPreferencesStore`)
- SOS trusted contact (`UserDefaultsSupportContactStore`)
- Achievement unlock set (`UserDefaultsAchievementStore`)
- Relapse history list (`UserDefaultsRelapseHistoryStore`) used for UI stats
- Local onboarding snapshot cache (`UserDefaultsOnboardingStore`)

### Important nuance
- Relapse timeline is already written to cloud (`sobriety_records`), but UI currently reads local relapse history store, so reinstall/new device can look like "fresh history" until cloud read path is implemented.

## 2) What to migrate in S07

Priority order:
1. Notification preferences
2. SOS trusted contact
3. Stats source-of-truth from cloud (`sobriety_records`) + achievement sync
4. Optional settings unification (app language override) if cross-device behavior is desired

## 3) Proposed DB migrations

## MIG-0701: Cloud notification preferences
Create `public.notification_preferences`:
- `user_id uuid primary key references public.users(id) on delete cascade`
- `daily_enabled boolean not null default true`
- `milestone_enabled boolean not null default true`
- `reengagement_enabled boolean not null default true`
- `daily_reminder_hour int not null default 20 check (daily_reminder_hour between 0 and 23)`
- `daily_reminder_minute int not null default 0 check (daily_reminder_minute between 0 and 59)`
- `quiet_hours_start int check (quiet_hours_start between 0 and 23)`
- `quiet_hours_end int check (quiet_hours_end between 0 and 23)`
- `updated_at timestamptz not null default now()`

RLS policies:
- select/insert/update/delete where `user_id = auth.uid()`

## MIG-0702: Cloud SOS trusted contact
Create `public.support_contacts`:
- `user_id uuid primary key references public.users(id) on delete cascade`
- `trusted_name text`
- `trusted_phone text`
- `updated_at timestamptz not null default now()`

RLS policies:
- select/insert/update/delete where `user_id = auth.uid()`

## MIG-0703: Achievement sync support
No schema change required if we keep using existing `public.achievements(type text, unique(user_id, type))`.

Optional hardening migration:
- add check convention for milestone keys (e.g. `type ~ '^milestone_[0-9]+$'`)
- add `created_at` index if read patterns require it (already has `achievements_user_unlocked_idx`)

## MIG-0704: Relapse/stats cloud read parity
No schema change required for baseline (already has `sobriety_records`).

Optional:
- add `updated_at` to `sobriety_records` for conflict diagnostics.

## 4) App-layer changes required

### Notifications
- add Supabase-backed `NotificationPreferencesStore`
- merge strategy:
  - on first sign-in: if cloud absent -> push local
  - otherwise pull cloud and overwrite local cache

### Support contact
- add Supabase-backed `SupportContactStore` with same merge strategy

### Stats / relapse parity
- read period summaries from `sobriety_records` (cloud) when signed in
- keep local store as offline fallback only

### Achievements
- write unlocked milestones to `public.achievements` as idempotent upsert pattern
- on load, union cloud + local while migration window is active

## 5) Rollout strategy

Phase A (safe additive):
- deploy DB migrations + RLS first
- ship app that dual-writes (local + cloud) but still reads local

Phase B (read switch):
- for signed-in users, read cloud-first with local fallback
- telemetry check for sync errors and read parity

Phase C (cleanup):
- stop relying on legacy local stores for signed-in state
- keep local only for signed-out/offline temporary cache

## 6) Backfill and risk notes

- Existing users already have cloud profile rows via `ensure_user_profile`.
- First-run migrator should push local prefs/contact/achievements once after sign-in.
- Handle 401/offline exactly like current sync paths (non-fatal UI, retry later).
- Keep all writes idempotent; no destructive migration needed.

## 7) Suggested execution checklist

1. Create migrations `MIG-0701` and `MIG-0702`.
2. Implement Supabase stores for prefs/contact.
3. Implement cloud read for sobriety periods in Stats.
4. Add achievement dual-write and cloud read.
5. Add regression checklist for:
   - reinstall -> sign-in -> data appears
   - new device sign-in -> profile/prefs/contact/stats parity
   - offline changes -> later sync convergence
