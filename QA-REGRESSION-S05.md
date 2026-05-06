# Sprint 05 Full Regression Checklist (QA-02)

## Scope
High-risk user flows:
- Auth
- Onboarding
- Home counter
- Stats
- AI chat
- SOS
- Relapse
- Notifications

## Automated
- [x] `swift test` passes
- [x] Core domain/state test suites pass (auth, onboarding, stats, relapse, notifications, AI service adapters)

## Manual - Simulator
- [ ] Auth: sign-in / sign-up / sign-out happy path
- [ ] Onboarding completion and restore path
- [ ] Home streak and milestone progress render correctly
- [ ] Stats values and period history continuity
- [ ] AI chat send/retry/history loading
- [ ] SOS open + quick actions + fallback
- [ ] Relapse flow reset + preserved history/milestones
- [ ] Notification preferences and quiet hours behavior

## Manual - Real Device
- [ ] Auth: sign-in / sign-up / sign-out
- [ ] Onboarding + Home + Stats consistency
- [ ] SOS and relapse core actions
- [ ] Notification delivery timing (daily/milestone/re-engagement)
- [ ] Quiet hours suppression/shift check

## Defect Triage
- [ ] No open P0 defects
- [ ] Any P1 has owner + ETA + mitigation

## Exit
- [ ] QA-02 marked done in `TASKS.md`

