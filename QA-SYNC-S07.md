# QA Sprint 07 — Sync and cross-device parity

**Build under test:**  
**Tester:**  
**Date:**

## Preconditions

- [ ] Signed-in test account with known Supabase user id (optional: verify rows in dashboard).
- [ ] Migrations through DB-02 applied on the environment this build targets.

## Cases

### A — Reinstall / same device

- [ ] Sign out (if applicable), delete app, reinstall, sign in.
- [ ] Profile: notification toggles, time, quiet hours match prior session (cloud source).
- [ ] Profile: SOS name/phone match cloud.
- [ ] Stats: milestones list matches cloud (`milestone_*` achievements).
- [ ] Stats: period list plausibly matches `sobriety_records` (current + past).

### B — Second device

- [ ] Device A: set distinct prefs + SOS + complete a milestone if possible.
- [ ] Device B: fresh app data, sign in same account.
- [ ] After main tabs load: prefs, SOS, stats/milestones converge (allow short delay; pull-to-refresh not required if auto).

### C — Offline / online

- [ ] Offline: change one notification pref; confirm local UI updates.
- [ ] Online: confirm no permanent error banner; optional Supabase row check.

### D — Relapse / history

- [ ] Log relapse on one device; confirm other device or reinstall shows updated periods after sync paths run.

## Sign-off

- [ ] No P0; P1 listed with owner if any.
- Results log: `QA-SYNC-S07-RESULTS.md` (create on completion).
