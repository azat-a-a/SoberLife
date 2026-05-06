# SoberLife Tasks Board

## Rules
- WIP limit: max 2 tasks in progress.
- Priority scale: P0 (critical), P1 (important), P2 (nice-to-have).
- Each task must have: Outcome, DoD, Estimate.
- Date format in notes/comments: YYYY-MM-DD.

---

## Todo

- [ ] REL-01 TestFlight pipeline hardening (Sprint 05)
  - Priority: P1
  - Outcome: repeatable beta distribution workflow.
  - DoD: build distributed to tester group; release notes template used; rollback steps validated once.
  - Estimate: 1 day

- [ ] STORE-01 App Store metadata prep (Sprint 05)
  - Priority: P2
  - Outcome: submission artifacts are review-ready ahead of release sprint.
  - DoD: screenshots/description/privacy labels draft complete and mapped to checklist.
  - Estimate: 1 day

- [ ] I18N-02 In-app language switch in Profile (Sprint 05)
  - Priority: P1
  - Outcome: user can choose app language from Profile (`System`/`English`/`Russian`).
  - DoD: runtime switch works across main screens; preference persists; `System` restores device language behavior.
  - Estimate: 1 day

- [ ] I18N-03 Add more languages (Sprint 06)
  - Priority: P1
  - Outcome: support additional locales: European languages + Chinese + Thai + Japanese.
  - DoD: locales added and selectable; no missing-key regressions on MVP screens; safety-critical copy reviewed in each added locale.
  - Estimate: 3 days

---

## In Progress

- [ ] BETA-01 Closed beta readiness gate (Sprint 05)
  - Started: 2026-05-06
  - Plan:
    - Freeze beta scope and document acceptance criteria (`BETA-READINESS.md`).
    - Prepare candidate build notes + known limitations.
    - Align launch checklist items required before inviting testers.
  - Exit criteria: readiness checklist approved and candidate build identified.

- [ ] BUG-01 Bug burn-down and stability fixes (Sprint 05)
  - Started: 2026-05-06
  - Plan:
    - Maintain live defect queue in `BUG-BURNDOWN-S05.md` with severity/owner/status.
    - Prioritize P0/P1 fixes first; verify with focused reruns.
    - Track crash/error trend against beta target and update mitigation notes.
  - Exit criteria: no open P0/P1; triaged P2 list with owners; stability trend acceptable for beta candidate.

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

- [x] AUTH-01 Email/password auth (Supabase)
  - Date: 2026-05-06 (replaces Apple Sign-In from 2026-05-05)
  - Notes: Client uses Supabase Auth email+password (`/auth/v1/token`, `/auth/v1/signup`); welcome screen with sign-in and create-account; D-014. Enable Email provider in Supabase project settings.

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
  - Notes: `UNNotificationCenterService` + `NotificationScheduleSync` reschedule repeating daily and next milestone one-shot; pending requests cleared by stable identifiers to prevent duplicates. Per-user time/quiet/category controls added in PUSH-02.

- [x] PUSH-02 Notification preferences and quiet hours
  - Date: 2026-05-05
  - Notes: `UserDefaultsNotificationPreferencesStore` + Profile toggles/time/quiet pickers; `NotificationQuietHours` shifts daily/milestone/re-engagement fire times; sync clears daily, milestone prefix, and re-engagement id before reschedule. Local-only persistence (server sync deferred).

- [x] IOS-APP-01 Xcode app target + TestFlight path
  - Date: 2026-05-05
  - Notes: `ios/SoberLife.xcodeproj` hosts the iOS 17+ app, local SPM dependency on repo root; `SoberLifeApp` wires live/placeholder `SessionState` from Info.plist Supabase keys; CI job `ios-xcodebuild` on `macos-latest`; see `ios/README.md` and `LAUNCH-CHECKLIST.md` for TestFlight prep (team, icon 1024, capabilities).

- [x] SAFE-01 Safety and empathy copy pass
  - Date: 2026-05-05
  - Notes: `EmpathyCopy` + softer onboarding/Home/Stats strings; DeepSeek system prompt updated for anti-shame and crisis escalation; SOS UI includes emergency-care disclaimer.

- [x] AI-02 Chat UI with cloud history
  - Date: 2026-05-05
  - Notes: AI Chat with `NavigationSplitView` thread list (up to 40), detail composer, **Try again** on failed assistant reply, `New chat` / New message; cloud load via user JWT + RLS; `UserDefaults` fallback; `ensure_user_profile` RPC + auth trigger migration for `public.users`; profile sync on `MainTabView` appear when JWT valid.

- [x] I18N-01 Multilingual UI (system language)
  - Date: 2026-05-06
  - Notes: Added package localization resources (`en`, `ru`) with `defaultLocalization = "en"`; introduced `L10n` helper; localized AppShell/Auth/Home/Chat/Stats/Profile/SOS and notification/auth copy paths (`EmpathyCopy`, `SessionState`, `NotificationScheduleSync`); added localization workflow notes in `ios/README.md`.

- [x] DATA-01 Analytics baseline (core events)
  - Date: 2026-05-06
  - Notes: Added centralized `AnalyticsTracker` with logging sink and `trackOnce` dedupe; instrumented `auth_started`, `auth_success`, `onboarding_complete`, `active_use_24h`, `sos_opened`, `relapse_logged`, `milestone_unlocked`; documented schema in `ANALYTICS.md` and weekly review template in `ANALYTICS-WEEKLY-NOTES.md`.

- [x] QA-01 End-to-End Smoke for Relapse + Notifications
  - Date: 2026-05-06
  - Notes: Manual smoke completed on simulator and real iPhone via `QA-SMOKE-S04.md`; results captured in `QA-SMOKE-S04-RESULTS.md`; no blocking P0/P1 issues reported.

- [x] QA-02 Full regression on core flows (Sprint 05)
  - Date: 2026-05-06
  - Notes: Automated regression (`swift test`) plus manual simulator/real-device pass completed via `QA-REGRESSION-S05.md`; results in `QA-REGRESSION-S05-RESULTS.md`; no open P0/P1 issues reported.

