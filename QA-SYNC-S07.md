# QA Sprint 07 — Sync and cross-device parity

**Build under test:** Release candidate (owner-confirmed).  
**Tester:** Project owner.  
**Date:** 2026-05-07

## Preconditions

- [x] Signed-in test account with known Supabase user id (optional: verify rows in dashboard).
- [x] Migrations through DB-02 applied on the environment this build targets.

## Cases

### A — Reinstall / same device

- [x] Sign out (if applicable), delete app, reinstall, sign in.
- [x] Profile: notification toggles, time, quiet hours match prior session (cloud source).
- [x] Profile: SOS name/phone match cloud.
- [x] Stats: milestones list matches cloud (`milestone_*` achievements).
- [x] Stats: period list plausibly matches `sobriety_records` (current + past).

### B — Second device

- [x] Device A: set distinct prefs + SOS + complete a milestone if possible.
- [x] Device B: fresh app data, sign in same account.
- [x] After main tabs load: prefs, SOS, stats/milestones converge (allow short delay; pull-to-refresh not required if auto).

### C — Offline / online

- [x] Offline: change one notification pref; confirm local UI updates.
- [x] Online: confirm no permanent error banner; optional Supabase row check.

### D — Relapse / history

- [x] Log relapse on one device; confirm other device or reinstall shows updated periods after sync paths run.

## Sign-off

- [x] No P0; P1 listed with owner if any.
- [x] Results log: `QA-SYNC-S07-RESULTS.md` (create on completion).
