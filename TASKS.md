# SoberLife Tasks Board

## Rules
- WIP limit: max 2 tasks in progress.
- Priority scale: P0 (critical), P1 (important), P2 (nice-to-have).
- Each task must have: Outcome, DoD, Estimate.
- Date format in notes/comments: YYYY-MM-DD.

---

## Todo

- [ ] AUTH-01 Apple Sign-In integration
  - Priority: P0
  - Outcome: user logs in securely with Apple ID.
  - DoD: login/logout works, error handling implemented, happy-path test done.
  - Estimate: 1.5 days

- [ ] ONB-01 Onboarding (goal, sobriety start date, daily alcohol cost)
  - Priority: P0
  - Outcome: user completes onboarding in 3-4 screens.
  - DoD: data persisted, skip option available, completion route to Home.
  - Estimate: 2 days

- [ ] HOME-01 Sobriety day counter on Home
  - Priority: P0
  - Outcome: clear, accurate sobriety counter visible on app launch.
  - DoD: date logic tested for timezone/day change edge cases.
  - Estimate: 1 day

- [ ] STATS-01 Basic stats (current streak, saved money)
  - Priority: P0
  - Outcome: meaningful progress indicators for motivation.
  - DoD: calculations validated against test fixtures.
  - Estimate: 1 day

- [ ] ACH-01 Milestones (7, 30, 90, 365)
  - Priority: P1
  - Outcome: user receives achievement badges on milestones.
  - DoD: unlock once-only logic verified.
  - Estimate: 1 day

- [ ] AI-01 DeepSeek edge function proxy
  - Priority: P0
  - Outcome: backend endpoint returns AI responses safely.
  - DoD: timeout/retry implemented, request/response logs sanitized.
  - Estimate: 2 days

- [ ] SOS-01 One-tap SOS support flow
  - Priority: P0
  - Outcome: user gets immediate support in cravings/crisis moments.
  - DoD: accessible from Home in 1 tap, fallback emergency info shown.
  - Estimate: 1.5 days

- [ ] REL-01 Relapse ("truth button") flow
  - Priority: P0
  - Outcome: user can report relapse without losing full history.
  - DoD: new sobriety period starts, history remains intact, supportive copy reviewed.
  - Estimate: 1.5 days

- [ ] PUSH-01 Daily and milestone notifications
  - Priority: P1
  - Outcome: retention support via non-intrusive reminders.
  - DoD: quiet hours supported, no duplicate notifications.
  - Estimate: 1.5 days

- [ ] SAFE-01 Safety and empathy copy pass
  - Priority: P0
  - Outcome: no shame language across app and AI prompts.
  - DoD: checklist completed, high-risk scenarios reviewed.
  - Estimate: 0.5 day

---

## In Progress

- [ ] DB-01 Supabase schema v1
  - Priority: P0
  - Outcome: database ready for onboarding and sobriety core.
  - DoD: migrations run cleanly and seed script works.
  - Estimate: 2 days

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

