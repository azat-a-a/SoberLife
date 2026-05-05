# Sprint 02 Plan (2 weeks)

## Sprint Objective
- Deliver a working user flow from authentication through onboarding to a functional Home screen with an accurate sobriety counter.

## Sprint Dates
- Start: 2026-05-20
- End: 2026-06-02

## Top Priorities
1. Apple Sign-In end-to-end
2. Minimal onboarding (3-4 screens)
3. Home screen with sobriety day counter
4. Basic stats and first milestone logic

## Committed Tasks

### AUTH-01 Apple Sign-In Integration
- Outcome: user signs in securely and reaches app shell.
- Tasks:
  - Integrate Sign in with Apple in iOS app.
  - Connect provider to Supabase Auth.
  - Handle login errors and canceled flow.
  - Implement logout and session invalidation.
- DoD:
  - Login works on real device.
  - Session restores after app restart.
  - Logout clears session and protected state.
  - Basic auth test checklist is completed.

### ONB-01 Minimal Onboarding Flow
- Outcome: user sets up sobriety profile in under 2 minutes.
- Tasks:
  - Screen 1: why user is here (optional goal).
  - Screen 2: sobriety start date ("Day 0").
  - Screen 3: daily alcohol cost (for savings stats).
  - Screen 4: notifications opt-in and finish.
  - Add skip option where non-critical.
- DoD:
  - Max 4 screens.
  - Required fields validated with friendly copy.
  - Completion writes data to DB and routes to Home.

### HOME-01 Sobriety Counter
- Outcome: user sees current sobriety streak immediately on Home.
- Tasks:
  - Implement date-based streak calculator.
  - Show current streak in days and progress to next milestone.
  - Add empty-state handling for missing setup data.
- DoD:
  - Counter updates correctly when day changes.
  - Timezone edge cases are covered by tests.
  - Home loads in under 1 second on warm start (target).

### STATS-01 Basic Stats (v1)
- Outcome: Home displays simple but motivating progress metrics.
- Tasks:
  - Calculate saved money from daily cost and sober days.
  - Show current streak and next milestone percentage.
  - Build reusable stat cards.
- DoD:
  - Calculations match backend expected values.
  - No negative or invalid values shown in UI.
  - Stats are hidden gracefully if onboarding data is incomplete.

### ACH-01 Milestones v1
- Outcome: user receives first achievement at 7 days.
- Tasks:
  - Add milestone rules for 7/30/90/365.
  - Persist unlocked achievements.
  - Trigger lightweight celebration UI.
- DoD:
  - Same milestone cannot unlock twice.
  - Unlock works after app relaunch and data reload.
  - 7-day milestone tested with seeded data.

### QA-01 End-to-End Smoke for Core Flow
- Outcome: team has confidence in the core loop before Sprint 03.
- Tasks:
  - Define smoke scenarios: sign-in -> onboarding -> home counter.
  - Run on at least one real iPhone and one simulator profile.
  - Log bugs and fix all P0/P1 issues found.
- DoD:
  - Smoke checklist fully passed.
  - No open P0/P1 issues at sprint end.

## Stretch Goals (if all committed work is done)
- UX-01 Add onboarding progress indicator.
- PERF-01 Cache user profile for faster first render.
- A11Y-01 VoiceOver labels for onboarding controls.

## Out of Scope for Sprint 02
- AI chat and SOS flow
- Push notification scheduling logic
- Relapse ("truth button") flow
- Social feed and friends

## Demo Checklist (End of Sprint)
- Show Apple Sign-In and logout.
- Show onboarding completion and DB persisted values.
- Show Home counter accuracy with mocked dates.
- Show milestone unlock for 7-day user fixture.

## Retro Prompts
- Where did user friction appear in onboarding?
- Which bugs repeated across auth/onboarding/home boundaries?
- What must be stabilized before AI + SOS in Sprint 03?

