# SoberLife Tasks Board

## Rules
- WIP limit: max 2 tasks in progress.
- Priority scale: P0 (critical), P1 (important), P2 (nice-to-have).
- Each task must have: Outcome, DoD, Estimate.
- Date format in notes/comments: YYYY-MM-DD.

---

## Todo

- [ ] OPS-01 DB-02 rollout verification
  - Priority: P1
  - Outcome: migrations and client sync verified in staging/prod; manual matrix done.
  - DoD: `OPS-DB02-ROLLOUT.md` completion record filled; issues triaged.
  - Estimate: 0.5 day
  - Notes: run before treating cloud parity as production-safe.

- [ ] S07-01 Execute Sprint 07 committed scope
  - Priority: P1
  - Outcome: ops gate closed, sync QA documented, i18n safety review started, one perf/obs item closed, analytics decision recorded.
  - DoD: see `SPRINT-07.md` (Gate 0 + committed work).
  - Estimate: 2 weeks
  - Notes: QA artifact `QA-SYNC-S07.md` / `QA-SYNC-S07-RESULTS.md`.

---

## In Progress

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

- [x] DB-02 Cloud state parity for profile/progress (Sprint 07)
  - Date: 2026-05-06
  - Priority was: P1
  - Notes: `notification_preferences` + `support_contacts` migration; `UserSettingsCloudSync` + `AchievementsCloudSync`; sobriety timeline hydrate from `sobriety_records` (`fetchHistorySnapshot`); milestones as `achievements.type` = `milestone_<days>` with merge-duplicates upsert. Plan: `MIGRATION-PLAN-S07.md`. Offline: local stores remain cache; sync errors non-fatal with banners.

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

- [x] STORE-01 App Store metadata prep (Sprint 05)
  - Date: 2026-05-06
  - Notes: Draft metadata package completed in `APP-STORE-METADATA-S05.md` (subtitle/description/keywords, screenshot plan, privacy labels draft, policy-sensitive language mapping, launch checklist coverage).

- [x] I18N-02 In-app language switch in Profile (Sprint 05)
  - Date: 2026-05-06
  - Notes: Profile language selector implemented with `LocalizationSettings` (`System`/`English`/`Russian`), runtime app-wide switch, persistence via `UserDefaults`, and localization resources updated for selector labels.

- [x] REL-01 TestFlight pipeline hardening (Sprint 05)
  - Date: 2026-05-06
  - Notes: Archive automation and release operations docs completed (`ios/scripts/testflight_archive.sh`, `ios/TESTFLIGHT-PIPELINE.md`, `ios/TESTFLIGHT-RELEASE-NOTES-TEMPLATE.md`, `ios/TESTFLIGHT-ROLLBACK.md`); upload/distribution confirmed in `ios/TESTFLIGHT-UPLOAD-CHECKLIST.md`.

- [x] BETA-01 Closed beta readiness gate (Sprint 05)
  - Date: 2026-05-06
  - Notes: Gate criteria completed and decision set to GO in `BETA-READINESS.md`; precheck evidence consolidated in `BETA-GO-NOGO-PRECHECK-S05.md`.

- [x] BUG-01 Bug burn-down and stability fixes (Sprint 05)
  - Date: 2026-05-06
  - Notes: Defect queue closed out in `BUG-BURNDOWN-S05.md`; `BUG-S05-002` fixed; crash/error trend review recorded; single open P2 (`BUG-S05-001`, CI queue) deferred with owner/mitigation.

- [x] I18N-03 Extended language pack (Sprint 06)
  - Date: 2026-05-06
  - Notes: Added `de`, `fr`, `es`, `it`, `pl`, `zh-Hans`, `th`, `ja` bundles and `AppLanguage` cases; source translations in `scripts/i18n/*.txt` with `make_bundle.py` + `merge_lproj.py`; coverage in `I18N-COVERAGE-S06.md`. Recommend native-speaker review for safety strings before wide release.

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

