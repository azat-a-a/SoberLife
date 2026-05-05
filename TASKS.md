# SoberLife Tasks Board

## Rules
- WIP limit: max 2 tasks in progress.
- Priority scale: P0 (critical), P1 (important), P2 (nice-to-have).
- Each task must have: Outcome, DoD, Estimate.
- Date format in notes/comments: YYYY-MM-DD.

---

## Todo

- Pull next committed work from `ROADMAP.md` / sprint files (journal sync, quiet hours UI, TestFlight).

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

- [x] PUSH-01 Daily and milestone notifications
  - Date: 2026-05-05
  - Notes: `UNNotificationCenterService` + `NotificationScheduleSync` reschedule daily (10:00, repeating) and next milestone one-shot; pending requests cleared by stable identifiers to prevent duplicates. `NotificationPreferences.quietHours*` still unused until settings UI defines hours.

- [x] SAFE-01 Safety and empathy copy pass
  - Date: 2026-05-05
  - Notes: `EmpathyCopy` + softer onboarding/Home/Stats strings; DeepSeek system prompt updated for anti-shame and crisis escalation; SOS UI includes emergency-care disclaimer.

- [x] AI-02 Chat UI with cloud history
  - Date: 2026-05-05
  - Notes: AI Chat tab with message list, send + retry via resend, `New chat`; loads latest `ai_conversations` row (type `chat`) via user JWT + RLS; local `UserDefaults` fallback; `SessionState.accessTokenIfAvailable()` for PostgREST.
  - Notes (follow-up): Sidebar list of recent threads (`NavigationSplitView`), **Try again** after failed assistant reply, `ensure_user_profile` RPC + auth trigger migration for `public.users` FK, `MainTabView` calls profile sync on appear.

