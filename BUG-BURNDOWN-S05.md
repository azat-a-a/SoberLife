# Sprint 05 Bug Burn-Down (BUG-01)

## Run Date
- 2026-05-06

## Baseline
- Automated regression: `swift test` passed (54 tests, 0 failures).
- Current known defect severity:
  - P0: 0
  - P1: 0
  - P2: 1 (CI infra queue)

## Open Defects

| ID | Severity | Area | Symptom | Owner | Status | Mitigation |
|---|---|---|---|---|---|---|
| BUG-S05-001 | P2 | CI / tooling | `markdown-lint` occasionally remains queued while other checks complete | Eng | Open | Merge gate relies on passing core checks; track workflow runner capacity and add retry policy if needed |
| BUG-S05-002 | P2 | iOS build validation | Xcode archive emitted warning: all interface orientations should be supported unless app is full-screen | iOS | Fixed (2026-05-06) | Added `UIRequiresFullScreen=true` in `ios/App/Info.plist`, re-ran archive, warning no longer present |

## Burn-Down Plan
1. Keep daily sweep for new P0/P1 from regression + manual QA.
2. Fix highest-severity item first (P0 -> P1 -> P2).
3. Re-run focused checks after each fix and update status table.

## Exit Criteria Tracking
- [x] No open P0 defects
- [x] No open P1 defects
- [x] P2 list triaged with owners
- [ ] Crash/error trend reviewed against beta candidate target

