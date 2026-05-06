# Sprint 06 Plan (2 weeks)

## Sprint Objective
- Execute production launch safely, monitor live health closely, and establish a fast hotfix loop for early post-release issues.

## Sprint Dates
- Start: 2026-07-15
- End: 2026-07-28

## Top Priorities
1. Production go-live with controlled rollout
2. Real-time monitoring and incident response readiness
3. Hotfix process for critical issues
4. Post-release learning and next-cycle planning
5. Language expansion beyond EN/RU

## Committed Tasks

### REL-01 Production Release Execution
- Outcome: app is successfully released in App Store with validated metadata and compliance.
- Tasks:
  - Final submission and release coordination.
  - Validate production config/secrets one last time.
  - Run release checklist before and after publication.
- DoD:
  - App published and available in target region(s).
  - Release checklist fully completed.
  - No unresolved blocker from App Review.

### REL-02 Staged Rollout and Guardrails
- Outcome: risk is reduced via controlled distribution and close early observation.
- Tasks:
  - Use phased rollout strategy where applicable.
  - Define rollback and feature-disable triggers.
  - Confirm emergency contacts/safety surfaces are reachable.
- DoD:
  - Rollout stages documented and followed.
  - Rollback trigger thresholds are explicit.
  - Safety-critical screens verified in production build.

### OBS-01 Live Monitoring and Alerts
- Outcome: team can detect and respond to production problems quickly.
- Tasks:
  - Monitor crash-free sessions, edge function latency/errors, push delivery health.
  - Tune alert thresholds based on live traffic.
  - Add daily health snapshot notes.
- DoD:
  - Critical alerts are routed and acknowledged.
  - Daily monitoring report produced during launch window.
  - No blind spots on top user journeys.

### HOTFIX-01 Hotfix Pipeline
- Outcome: critical defects can be patched quickly with minimal process friction.
- Tasks:
  - Define severity rubric (P0/P1/P2) and SLA targets.
  - Create branch/release procedure for emergency patches.
  - Prepare hotfix verification checklist.
- DoD:
  - At least one hotfix dry run completed.
  - SLA and ownership documented.
  - Hotfix path tested end-to-end.

### QA-01 Production Smoke and Safety Validation
- Outcome: live app behavior matches beta expectations.
- Tasks:
  - Smoke test production flows: auth, onboarding, counter, AI chat, SOS, relapse, notifications.
  - Verify hotline fallback and non-judgment copy in production.
  - Re-check timezone/date edge cases in real production data.
- DoD:
  - Smoke suite passed within 24h of launch.
  - No P0 issues in safety-critical flows.
  - Any P1 issues have owners and ETA.

### DATA-01 Post-Launch Metrics Review
- Outcome: first product signals are captured for iteration decisions.
- Tasks:
  - Review D1 retention, SOS usage-return rate, 7-day milestone progression.
  - Compare expected vs actual funnel drop-offs.
  - Identify top 3 product improvements for next sprint cycle.
- DoD:
  - Post-launch KPI report completed.
  - Priority list for next cycle is agreed.
  - At least one quick-win improvement ticket created per top issue.

### OPS-01 User Feedback Loop
- Outcome: incoming user feedback is triaged and converted into action.
- Tasks:
  - Set feedback intake channels and triage labels.
  - Categorize feedback: bug, confusion, missing feature, trust/safety concern.
  - Feed high-signal themes into roadmap updates.
- DoD:
  - Feedback triage process is documented.
  - High-severity feedback has clear owner.
  - Weekly synthesis note produced.

### I18N-03 Extended Language Pack (EU + CJK + Thai)
- Outcome: app supports additional target locales for post-launch growth.
- Tasks:
  - Add localization resources for selected European languages and Asian locales: Chinese, Thai, Japanese.
  - Define language list and fallback policy (e.g. region-specific Chinese variants and fallback to English when missing).
  - Localize MVP surfaces consistently (Auth/Home/Stats/Chat/SOS/Profile/settings).
  - Run linguistic QA pass for critical recovery/safety copy.
- DoD:
  - New locales are selectable and render without missing-key regressions on MVP screens.
  - Safety-critical strings (SOS, relapse, disclaimers) reviewed in each added locale.
  - Smoke checks pass for each newly added language on simulator/device.
  - Localization coverage report updated in docs.

## Stretch Goals (if all committed work is done)
- EXP-01 A/B test plan draft for onboarding improvements.
- UX-01 Microcopy refinement pass based on real user language.
- PERF-01 Additional optimization for chat history loading.

## Out of Scope for Sprint 06
- Major new features (social feed, groups)
- Subscription and paywall implementation
- Large architectural refactors

## Demo Checklist (End of Sprint)
- Show production release timeline and final checklist.
- Show live health dashboard trends during launch window.
- Show incident/hotfix drill outcome.
- Show post-launch KPI review and next sprint priorities.

## Retro Prompts
- What launch risk did we underestimate?
- Which monitoring signals were most useful?
- What should be automated before next major release?

