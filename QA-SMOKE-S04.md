# Sprint 04 Smoke Checklist

Scenario focus: `streak -> relapse -> new streak -> milestone` and notification behavior.

## Environment
- [ ] Build from latest `main`
- [ ] Test on simulator
- [ ] Test on at least one real iPhone
- [ ] Notifications permission granted

## Relapse Flow
- [ ] User with active streak opens Home
- [ ] Tap truth button (`I had a drink (new period)`)
- [ ] Confirm relapse action
- [ ] Current streak resets to new period
- [ ] Previous streak remains visible in history/stats
- [ ] Milestones already earned are still present

## Post-Relapse Continuity
- [ ] New period start date equals today
- [ ] Stats screen reflects new current streak
- [ ] Multi-period history remains ordered and readable
- [ ] No crashes or blocked UI states

## Notifications
- [ ] Daily reminder scheduled at configured time
- [ ] Milestone reminder scheduled (if next target exists)
- [ ] Re-engagement reminder scheduled after inactivity window
- [ ] Quiet hours suppress/shift non-critical notifications
- [ ] No duplicate notifications for the same logical event

## Analytics Baseline Sanity
- [ ] `relapse_logged` emitted on relapse confirmation
- [ ] `sos_opened` emitted when SOS is opened from Home
- [ ] `onboarding_complete` emitted once per user
- [ ] `milestone_unlocked` emitted once per milestone per user

## Exit Criteria
- [ ] Checklist passed on simulator and device
- [ ] No open P0/P1 bugs

