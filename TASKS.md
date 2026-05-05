# SoberLife Tasks Board

## Rules
- WIP limit: max 2 tasks in progress.
- Priority scale: P0 (critical), P1 (important), P2 (nice-to-have).
- Each task must have: Outcome, DoD, Estimate.
- Date format in notes/comments: YYYY-MM-DD.

---

## Todo

- [ ] PUSH-02 Notification preferences and quiet hours
  - Priority: P1
  - Outcome: user controls daily time, quiet window, and categories (daily / milestone / re-engagement).
  - DoD: settings persisted (local + server when sync exists); scheduler respects toggles and quiet hours; no duplicate fires.
  - Estimate: 1.5 days

- [ ] IOS-APP-01 Xcode app target + TestFlight path
  - Priority: P1
  - Outcome: installable iOS app from repo, ready for internal TestFlight.
  - DoD: app target builds, signs, uses package modules; `LAUNCH-CHECKLIST.md` pre-beta items ticked for build/signing.
  - Estimate: 2 days

- [ ] DATA-01 Analytics baseline (core events)
  - Priority: P2
  - Outcome: funnel events for onboarding, SOS, relapse, milestones (schema + one sink).
  - DoD: events documented; single provider stub (e.g. logging or vendor); no duplicate fire on replay.
  - Estimate: 1 day

---

## In Progress

- None

---

## Done

- [x] PLAN-01 Product concept consolidation
  - Notes: consolidated from "Концепция приложения SoberLife".

- [x] SETUP-01 CI + environment baseline
  - Date: 2026-05-05
  - Notes: git initialized, Swift package scaffold added, CI workflow created (build/test/markdown lint).

- [x] ARCH-01 Architecture baseline
  - Date: 2026-05-05
  - Notes: architecture document added, service contracts defined (Auth, Supabase, AI, Notification), edge function drafts captured.

- [x] DB-01 Supabase schema v1
  - Date: 2026-05-05
  - Notes: initial migration and seed script added under supabase/ with core tables, constraints, and indexes.

- [x] SEC-01 RLS and access policies
  - Date: 2026-05-05
  - Notes: RLS enabled and owner-based policies added for all core tables using auth.uid().

- [x] IOS-01 App skeleton
  - Date: 2026-05-05
  - Notes: SwiftUI app shell added with tab navigation, placeholder screens, and session-state auth placeholder flow.

- [x] AUTH-01 Apple Sign-In integration
  - Date: 2026-05-05
  - Notes: Apple Sign-In token provider, live iOS token bridge, Supabase auth exchange service, and session wiring factory added with tests.

- [x] ONB-01 Onboarding (goal, sobriety start date, daily alcohol cost)
  - Date: 2026-05-05
  - Notes: 4-step onboarding flow added with skip support and local profile persistence; completed users route directly to Home tabs.

- [x] DATA-SYNC-01 Onboarding + sobriety profile in Supabase
  - Date: 2026-05-05
  - Notes: `SobrietySupabaseSync` patches `users` and current `sobriety_records`; `SobrietyCloudSync` runs after onboarding and after relapse (with JWT); banner on sync failure; Core uses `SobrietyProfileSnapshot` to avoid layering violations.

- [x] RELI-01 Session refresh + critical-path error states
  - Date: 2026-05-05
  - Notes: Added `SessionState.handleUnauthorizedSession()` as re-sign-in path; 401 handling wired in cloud sync, profile ensure, and AI chat; offline fallbacks surfaced in Home/Chat/SOS copy without silent failures.

- [x] HOME-01 Sobriety day counter on Home
  - Date: 2026-05-05
  - Notes: Home now reads onboarding profile, computes sobriety days via SobrietyCounter, and shows next milestone progress.

- [x] STATS-01 Basic stats (current streak, saved money)
  - Date: 2026-05-05
  - Notes: Stats tab now computes current streak, saved money, next milestone, and progress percentage from onboarding profile.

- [x] ACH-01 Milestones (7, 30, 90, 365)
  - Date: 2026-05-05
  - Notes: Milestone unlock logic added with once-only persistence and badges rendered in Stats tab.

- [x] AI-01 DeepSeek edge function proxy
  - Date: 2026-05-05
  - Notes: Added deepseek-chat Edge Function with timeout/retry and safe logs; implemented DeepSeekAIService with timeout/retry and tests.

- [x] SOS-01 One-tap SOS support flow
  - Date: 2026-05-05
  - Notes: SOS button on Home opens sheet with grounding steps, optional DeepSeek SOS message when `AppShellView` is constructed with `authWiring`, trusted contact call/SMS from Profile, crisis disclaimer and Find a Helpline link.

- [x] REL-01 Relapse ("truth button") flow
  - Date: 2026-05-05
  - Notes: Honesty flow records `RelapseEvent`, shifts `sobrietyStartDate` to today without clearing `AchievementStore`; Stats show best streak and check-in count.

- [x] REL-02 Relapse history in UI + multi-period stats
  - Date: 2026-05-05
  - Notes: `SobrietyJourney.periodSummaries` + Stats tab cards for current and past periods (newest-first); tests for ordering, multi-period stats wiring, and milestone persistence without duplicates after relapse.

- [x] PUSH-01 Daily and milestone notifications
  - Date: 2026-05-05
  - Notes: `UNNotificationCenterService` + `NotificationScheduleSync` reschedule daily (10:00, repeating) and next milestone one-shot; pending requests cleared by stable identifiers to prevent duplicates. `NotificationPreferences.quietHours*` still unused until settings UI defines hours.

- [x] SAFE-01 Safety and empathy copy pass
  - Date: 2026-05-05
  - Notes: `EmpathyCopy` + softer onboarding/Home/Stats strings; DeepSeek system prompt updated for anti-shame and crisis escalation; SOS UI includes emergency-care disclaimer.

- [x] AI-02 Chat UI with cloud history
  - Date: 2026-05-05
  - Notes: AI Chat with `NavigationSplitView` thread list (up to 40), detail composer, **Try again** on failed assistant reply, `New chat` / New message; cloud load via user JWT + RLS; `UserDefaults` fallback; `ensure_user_profile` RPC + auth trigger migration for `public.users`; profile sync on `MainTabView` appear when JWT valid.

