# Weekly Ritual (No Jira)

## Purpose
- Keep delivery predictable with lightweight planning, daily focus, and fast feedback loops.

## Core Rules
- Max WIP: 2 tasks in progress.
- Prioritize P0 before P1/P2.
- No new feature starts until current task has clear DoD.
- Critical recovery/safety issues always preempt normal work.

## Monday (45-60 min): Weekly Planning
- Review `TASKS.md` and move completed items to `Done`.
- Pick 5-8 tasks max for the week.
- Confirm dependencies and blockers.
- Update current sprint file (`SPRINT-0X.md`) if scope changed.
- Define weekly success checkpoints:
  - Product checkpoint (user value delivered)
  - Technical checkpoint (stability/performance/security)

## Daily (10-15 min): Standup With Yourself
- Update `TASKS.md` sections (`Todo`, `In Progress`, `Done`).
- Answer 3 questions:
  - What was completed yesterday?
  - What is the single highest-priority task today?
  - What is blocked and how to unblock it today?
- If blocked > 1 day: create a fallback path in `DECISIONS.md`.

## Midweek (Wednesday, 20 min): Scope Check
- Compare actual progress vs sprint objective.
- If behind:
  - Drop lowest-priority task(s).
  - Keep objective fixed, reduce scope.
- If ahead:
  - Pull only one stretch task.

## Friday (45 min): Demo + Retrospective
- Run a mini-demo using sprint demo checklist.
- Verify:
  - No open P0 issues
  - P1 issues have owner and ETA
  - Core flow still passes smoke checks
- Write a short retrospective:
  - What worked well?
  - What slowed work most?
  - What one process change to apply next week?

## Release Week Add-On
- Increase monitoring cadence to daily KPI review.
- Freeze non-critical feature work.
- Keep hotfix-ready branch and checklist current.

## Required Files Hygiene (Every Friday)
- `TASKS.md`: all statuses accurate
- `SPRINT-0X.md`: objective status updated
- `DECISIONS.md`: important decisions logged
- `ROADMAP.md`: only update when timeline/strategy changes

## Quick Templates

### Daily Note
```md
## Daily Update (YYYY-MM-DD)
- Done:
- In Progress:
- Blockers:
- Decisions:
- Next:
```

### Weekly Retro
```md
## Weekly Retro (Week NN)
- Wins:
- Pain points:
- Metrics snapshot:
- Process change for next week:
```

### Blocker Log
```md
## Blocker
- Task:
- Impact:
- Tried:
- Decision:
- Owner:
- ETA:
```

