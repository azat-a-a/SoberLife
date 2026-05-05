# Sprint 05 Plan (2 weeks)

## Sprint Objective
- Reach closed-beta quality by hardening stability, validating key recovery journeys, and preparing release assets/processes.

## Sprint Dates
- Start: 2026-07-01
- End: 2026-07-14

## Top Priorities
1. Beta hardening for core user journeys
2. Structured QA and bug burn-down
3. Performance, observability, and reliability improvements
4. App Store and TestFlight release preparation

## Committed Tasks

### BETA-01 Closed Beta Readiness Gate
- Outcome: product is safe and stable enough for invited beta users.
- Tasks:
  - Define beta entry criteria and acceptance checklist.
  - Freeze MVP scope for beta window.
  - Prepare beta rollout notes and known limitations.
- DoD:
  - Readiness checklist approved.
  - Scope freeze documented and communicated.
  - Beta candidate build identified and tagged.

### QA-01 Full Regression on Core Flows
- Outcome: confidence across high-risk user paths.
- Tasks:
  - Execute regression suite: auth, onboarding, home counter, stats, AI chat, SOS, relapse, notifications.
  - Add reproducible bug reports with severity labels.
  - Retest fixes before closure.
- DoD:
  - 100% of P0/P1 scenarios tested.
  - No open P0 defects.
  - P1 defects only allowed with explicit mitigation and owner.

### BUG-01 Bug Burn-Down and Stability Fixes
- Outcome: lower crash/error rate and smoother UX.
- Tasks:
  - Resolve top crash signatures first.
  - Fix high-frequency UX breakpoints (empty states, retry loops, stale data).
  - Improve sync consistency after reconnect.
- DoD:
  - Crash-free sessions >= 99% on beta candidate.
  - Error rate trend is stable or decreasing over sprint.
  - No critical data loss paths remain.

### PERF-01 Performance Pass
- Outcome: core screens feel responsive on representative devices.
- Tasks:
  - Profile cold start and first Home render.
  - Optimize heavy render paths in chat/history screens.
  - Reduce redundant network calls on app resume.
- DoD:
  - Home warm open target <= 1s median.
  - AI chat screen open target <= 1.5s median.
  - Measured improvements documented before/after.

### OBS-01 Observability and Alerting
- Outcome: issues can be detected and triaged quickly during beta.
- Tasks:
  - Finalize error and latency dashboards.
  - Add alerts for edge function failures and notification anomalies.
  - Add runbook for common incidents.
- DoD:
  - Alert thresholds defined and tested.
  - On-call style response playbook available.
  - Dashboard links added to team docs.

### REL-01 TestFlight Pipeline
- Outcome: repeatable beta distribution process.
- Tasks:
  - Automate/archive beta build process.
  - Configure tester groups and release notes template.
  - Add rollback guidance for bad beta builds.
- DoD:
  - Build successfully distributed to TestFlight group.
  - Release notes generated from template.
  - Rollback procedure tested once.

### STORE-01 App Store Prep (Draft)
- Outcome: release artifacts are mostly ready before final sprint.
- Tasks:
  - Prepare screenshots, subtitle, and app description drafts.
  - Finalize privacy nutrition labels draft.
  - Validate policy-sensitive language (medical disclaimer, safety wording).
- DoD:
  - Metadata draft complete and reviewable.
  - Required legal text mapped to in-app screens.
  - No blocker gaps in store submission checklist.

## Stretch Goals (if all committed work is done)
- A11Y-01 Accessibility sweep for VoiceOver and dynamic type.
- I18N-01 English localization pass for beta messages.
- QA-02 Exploratory test charter focused on relapse edge cases.

## Out of Scope for Sprint 05
- Social feed and friend system
- Group support communities
- Premium paywall and billing integration
- Large visual redesign

## Demo Checklist (End of Sprint)
- Show regression status and bug burn-down trend.
- Show crash/error metrics against sprint start baseline.
- Show TestFlight build delivery and release notes.
- Show App Store metadata draft package.

## Retro Prompts
- Which defect classes consumed most time and why?
- What did beta testers find that internal QA missed?
- What is still risky before production release?

