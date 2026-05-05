# Sprint 04 Plan (2 weeks)

## Sprint Objective
- Implement relapse recovery flow and reliable notification system, then harden stability ahead of beta readiness.

## Sprint Dates
- Start: 2026-06-17
- End: 2026-06-30

## Top Priorities
1. Relapse ("truth button") flow without shame/reset narrative
2. Daily and milestone push notifications
3. Reliability hardening for auth/data/AI boundaries
4. Analytics baseline for retention and SOS outcomes

## Committed Tasks

### REL-01 Relapse Recovery Flow (Truth Button)
- Outcome: user can report a relapse safely and continue recovery path.
- Tasks:
  - Add "truth button" entry point from Home and Profile.
  - Build guided flow: acknowledge -> reflect optional trigger -> set new start date.
  - Close current sobriety period and create new one in `sobriety_records`.
  - Keep lifetime/total progress visible in stats.
- DoD:
  - Relapse can be logged in under 60 seconds.
  - Prior streak is preserved in history and not deleted.
  - UI messaging is non-judgmental and recovery-oriented.
  - Data integrity checks pass (only one current period per user).

### REL-02 Relapse-Aware Stats and Achievements
- Outcome: stats remain meaningful after relapse events.
- Tasks:
  - Update metrics to show current streak + lifetime sober days.
  - Prevent accidental duplicate achievement unlocks after new period starts.
  - Add simple relapse markers in history view.
- DoD:
  - Stats calculations match fixtures across multi-period scenarios.
  - Achievement logic is deterministic and idempotent.
  - History display remains understandable for users.

### PUSH-01 Notification Scheduling
- Outcome: users receive timely, low-friction reminders.
- Tasks:
  - Implement daily motivation push.
  - Implement milestone unlock push.
  - Implement gentle return push after inactivity.
  - Add local fallback behavior for missing network.
- DoD:
  - Notifications fire at configured user time.
  - No duplicate notifications for same event/day.
  - Inactive user reminder respects cooldown rules.

### PUSH-02 Notification Preferences + Quiet Hours
- Outcome: users control reminder volume and timing.
- Tasks:
  - Add settings for on/off by category (daily, milestone, re-engagement).
  - Add quiet hours window.
  - Save preferences in backend and cache locally.
- DoD:
  - Quiet hours suppress non-critical notifications.
  - Preferences persist across app restarts/devices.
  - Category toggles are reflected in scheduler behavior.

### RELI-01 Stability and Error Handling Pass
- Outcome: fewer disruptions in critical support moments.
- Tasks:
  - Audit and improve retries/backoff for network-dependent flows.
  - Add defensive handling for stale sessions and token refresh edge cases.
  - Improve error states for Home, Chat, SOS, and Relapse flows.
- DoD:
  - No uncaught exceptions in tested core paths.
  - Token refresh failures show actionable recovery prompt.
  - Offline/timeout scenarios are handled gracefully.

### DATA-01 Analytics Baseline
- Outcome: team can measure retention and intervention effectiveness.
- Tasks:
  - Track key events: onboarding_complete, sos_opened, relapse_logged, milestone_unlocked.
  - Add funnel views for auth -> onboarding -> active use.
  - Add lightweight weekly dashboard notes template.
- DoD:
  - Events are emitted once per user action.
  - Event schema is documented and versioned.
  - Dashboard shows at least D1, D7, SOS-return metric trend.

### QA-01 End-to-End Smoke for Relapse + Notifications
- Outcome: confidence before beta stabilization sprint.
- Tasks:
  - Scenario test: streak -> relapse -> new streak -> milestone.
  - Verify notification behavior with real device time settings.
  - Validate stats continuity and historical views after relapse.
- DoD:
  - Smoke checklist passes on simulator and device.
  - No open P0/P1 bugs at sprint close.

## Stretch Goals (if all committed work is done)
- UX-01 Guided breathing mini-flow in SOS quick actions.
- COPY-01 Expanded supportive templates for post-relapse first 72h.
- OBS-01 Notification delivery diagnostics panel (internal).

## Out of Scope for Sprint 04
- Social feed/friends
- Group support features
- Photodiary and rich journaling
- Monetization paywall/subscription logic

## Demo Checklist (End of Sprint)
- Show complete relapse logging flow and resulting stats.
- Show daily + milestone + inactivity push behavior.
- Show preferences and quiet hours effects.
- Show analytics events arriving and visible in baseline dashboard.

## Retro Prompts
- Did relapse flow reduce shame and encourage return?
- Which notification rules felt useful vs noisy?
- What reliability gaps remain before closed beta?

