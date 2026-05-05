# Launch Checklist

This checklist covers preparation and execution from pre-beta to the first 48 hours after release.

## Severity Levels
- P0: Critical user safety/data-loss/app unusable issue. Immediate action.
- P1: Major functionality degraded, no safe workaround.
- P2: Non-critical defect or polish issue.

---

## 1) Pre-Beta Checklist

### Product and Scope
- [ ] MVP scope frozen and documented.
- [ ] All out-of-scope items explicitly listed.
- [ ] Core user journeys confirmed:
  - [ ] Auth
  - [ ] Onboarding
  - [ ] Home counter
  - [ ] AI chat
  - [ ] SOS flow
  - [ ] Relapse flow

### Safety and Compliance
- [ ] Medical disclaimer visible and approved.
- [ ] Emergency/hotline information reachable in-app.
- [ ] Non-judgment language pass completed.
- [ ] Privacy policy and terms available in app.

### Technical Readiness
- [ ] CI is green on release candidate branch.
- [ ] Crash reporting and error monitoring active.
- [ ] Edge function secrets configured for stage/prod.
- [ ] Database migrations are up-to-date and reproducible.
- [ ] RLS policies validated for all user data tables.

### QA
- [ ] Regression suite executed on simulator and at least one real device.
- [ ] No open P0 defects.
- [ ] P1 defects triaged with owner + ETA + mitigation.

---

## 2) Closed Beta Checklist (TestFlight)

### Distribution
- [ ] Beta build uploaded and processed in TestFlight.
- [ ] Tester groups configured.
- [ ] Beta release notes published.

### Observability
- [ ] Dashboards ready for:
  - [ ] Crash-free sessions
  - [ ] AI latency/error rate
  - [ ] Notification delivery health
- [ ] Alerts tested and routed.

### Feedback Loop
- [ ] Beta feedback intake channel defined.
- [ ] Triage labels prepared (bug/confusion/feature/safety).
- [ ] Daily beta review owner assigned.

### Exit Criteria
- [ ] Crash-free sessions >= 99% on beta candidate.
- [ ] No unresolved P0.
- [ ] P1 list acceptable for release with mitigations.

---

## 3) Release Week Checklist

### Submission and Metadata
- [ ] App Store metadata finalized (title, subtitle, description, keywords).
- [ ] Screenshots updated and accurate.
- [ ] Privacy nutrition labels verified.
- [ ] App Review notes include safety/disclaimer context.

### Go/No-Go Meeting
- [ ] Product readiness confirmed.
- [ ] Engineering readiness confirmed.
- [ ] QA sign-off complete.
- [ ] Support/incident owner assigned.
- [ ] Rollback plan reviewed.
- [ ] Final decision recorded in `DECISIONS.md`.

### Production Readiness
- [ ] Production environment and secrets verified.
- [ ] Feature flags validated.
- [ ] Alert thresholds reviewed for launch traffic.
- [ ] Hotfix branch and process ready.

---

## 4) Release Day Runbook

### Before Publishing
- [ ] Run production smoke tests on latest build.
- [ ] Confirm monitoring dashboards are open and staffed.
- [ ] Confirm incident channel is active.

### During Publishing
- [ ] Track app status in App Store Connect.
- [ ] Announce release internally with build/version number.
- [ ] Start launch watch window timer.

### Immediate Post-Publish (0-4h)
- [ ] Check auth success rate.
- [ ] Check crash rate trend.
- [ ] Check AI response latency and errors.
- [ ] Check SOS flow availability.
- [ ] Check notification pipeline health.
- [ ] Log issues and assign owners live.

---

## 5) First 48 Hours After Release

### Monitoring Cadence
- [ ] Hourly checks for first 8 hours.
- [ ] Every 4 hours until 24h.
- [ ] Twice during 24-48h window.

### KPI Snapshot
- [ ] Installs and activations.
- [ ] Onboarding completion rate.
- [ ] D1 early proxy metrics (same-day return).
- [ ] SOS usage and return behavior.

### Quality and Incidents
- [ ] Triage all incoming user feedback.
- [ ] Resolve/mitigate any P0 immediately.
- [ ] Decide for each P1: hotfix now vs scheduled patch.

### Communication
- [ ] Daily launch summary posted.
- [ ] Decision outcomes logged in `DECISIONS.md`.
- [ ] Next patch scope drafted in `TASKS.md`.

---

## 6) Hotfix Checklist

### Trigger
- [ ] P0 confirmed OR severe P1 with broad impact.

### Execution
- [ ] Repro case documented.
- [ ] Minimal fix implemented.
- [ ] Focused regression executed on impacted flows.
- [ ] New build distributed (TestFlight/App Store as needed).

### Closure
- [ ] Incident note written (root cause + prevention).
- [ ] Monitoring confirms recovery.
- [ ] Follow-up tasks created in `TASKS.md`.

---

## 7) Post-Launch Review (End of Week 1)

- [ ] Compare actual KPI vs targets in `ROADMAP.md`.
- [ ] Identify top 3 friction points.
- [ ] Define next sprint priorities.
- [ ] Archive release notes and lessons learned.

