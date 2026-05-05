# SoberLife Planning Workspace

This repository currently contains the product and delivery planning system for SoberLife.

## What Is Inside

- `ROADMAP.md` - high-level phases, KPI targets, risks, and post-MVP direction.
- `SPRINT-01.md` - foundation sprint plan.
- `SPRINT-02.md` - auth, onboarding, and sobriety counter sprint plan.
- `SPRINT-03.md` - AI chat and SOS sprint plan.
- `SPRINT-04.md` - relapse flow, notifications, and hardening sprint plan.
- `SPRINT-05.md` - beta readiness and release preparation sprint plan.
- `SPRINT-06.md` - production launch, monitoring, and hotfix sprint plan.
- `TASKS.md` - lightweight kanban board (`Todo / In Progress / Done`).
- `DECISIONS.md` - architecture and product decision log.
- `WEEKLY-RITUAL.md` - weekly operating cadence without Jira.
- `DAILY-NOTES.md` - prefilled daily execution log template for the next 2 weeks.
- `LAUNCH-CHECKLIST.md` - operational checklist from pre-beta to first 48 hours post-release.
- `Концепция приложения SoberLife.docx` - original concept source document.

## How To Work (No Jira)

1. Start with `TASKS.md` and pick top priorities (P0 first).
2. Keep current sprint scope aligned with the active `SPRINT-0X.md`.
3. Record meaningful technical/product decisions in `DECISIONS.md`.
4. Follow weekly cadence from `WEEKLY-RITUAL.md`.
5. Update `ROADMAP.md` only for timeline or strategy changes.

## Minimal Weekly Flow

- Monday: plan 5-8 tasks for the week.
- Daily: update `TASKS.md`, keep WIP <= 2.
- Wednesday: scope check and de-scope if needed.
- Friday: run sprint demo checklist and write retro note.

## Priority Model

- `P0` - critical path or user safety impact.
- `P1` - important but not blocking launch objective.
- `P2` - useful improvements and polish.

## Documentation Style Guide

- Date format: `YYYY-MM-DD` in all planning files.
- Task status format: `Todo`, `In Progress`, `Done`.
- Task fields format: `Priority`, `Outcome`, `DoD`, `Estimate`.
- Sprint date sections use `Start` and `End` fields.
- Use `DoD` wording consistently (instead of mixed "acceptance"/"done" labels).

## Definition of Done (Default)

- User-visible outcome is testable.
- Acceptance criteria from sprint/task are met.
- No silent failure path in happy or common error flows.
- Relevant docs are updated (`TASKS`, `DECISIONS`, sprint file).

## Suggested Next Steps

- Start execution from `SPRINT-01.md`.
- Use `DAILY-NOTES.md` to keep a short day-by-day execution history.
- Follow `LAUNCH-CHECKLIST.md` during beta and release windows.
- Add engineering setup files once implementation begins (code, CI config, env templates).

