# Sprint 07 Plan (2 weeks)

## Sprint objective

- Close the **operational gap** after DB-02 (verified rollout, sync QA, monitoring clarity).
- Ship **low-risk polish** that reduces launch risk: i18n safety pass, performance/observability debt where bounded.
- Lock **next milestone** toward App Store / production (aligns with themes in `SPRINT-06.md`; calendar below is the *near-term* engineering window—adjust dates to your actual planning).

## Sprint dates (suggested)

- Start: **2026-05-07**
- End: **2026-05-20**

## Progress

- [x] **Gate 0 (OPS):** `OPS-DB02-ROLLOUT.md` fully completed (2026-05-07); staging + prod verified; completion record filled.
- [x] **QA-03:** `QA-SYNC-S07.md` + `QA-SYNC-S07-RESULTS.md` — all sections passed (2026-05-07).
- [x] **I18N-04:** `I18N-REVIEW-S07.md` signed off; no blockers (optional native pass before wide locale rollout per `I18N-COVERAGE-S06.md`).
- [x] **TECH-01 (one item):** Main tab cloud bootstrap calls `ensure_user_profile` once per successful wake, then settings + achievements bootstraps skip duplicate ensure (`skipEnsureProfile`).
- [x] **DATA-02:** **D-015** in `DECISIONS.md`; `ANALYTICS.md` updated.

## Relationship to other sprint docs

- **`SPRINT-05.md`**: beta/TestFlight hardening (largely done).
- **`SPRINT-06.md`**: heavier **launch + live ops** block (dates in that file may target a later window—reconcile with your real release calendar).
- **This sprint (07)**: **verify cloud parity in the field** and prepare the product/engineering system for the launch sprint.

---

## Gate 0 — Operations (must complete early)

**Artifact:** `OPS-DB02-ROLLOUT.md`

- **Status (2026-05-07):** Complete — migrations, RLS smoke, app matrix, monitoring/rollback posture, completion record filled; no P0/P1 sync issues.

---

## Committed work

### OPS-01 DB-02 rollout verification

- **Outcome:** Staging/prod and client behavior match expectations for prefs, SOS contact, sobriety history, achievements.
- **DoD:** `OPS-DB02-ROLLOUT.md` completed; any issues filed with severity and owner.

### QA-03 Cross-device / sync regression

- **Outcome:** Repeatable smoke for “second device” and “reinstall” on core flows (auth, home, stats, profile, notifications schedule).
- **Tasks:** Run **`QA-SYNC-S07.md`**; capture outcomes in **`QA-SYNC-S07-RESULTS.md`** (create when run).
- **DoD:** One full pass documented on a release candidate build.

### I18N-04 Safety-critical copy review (extended locales)

- **Outcome:** Native or professional review for **SOS, relapse, disclaimers** in locales added under I18N-03 (`I18N-COVERAGE-S06.md`).
- **DoD:** Review notes stored (append to `I18N-COVERAGE-S06.md` or short `I18N-REVIEW-S07.md`); blockers tracked in `TASKS.md`.

### TECH-01 Performance / observability (bounded)

- **Outcome:** Address **one** concrete item carried from Sprint 05 (`PERF-01` / `OBS-01`)—e.g. reduce redundant sync calls on resume **or** document monitoring links for beta.
- **DoD:** Short before/after note in sprint retro section below; no open-ended refactor.

### DATA-02 Analytics destination decision

- **Outcome:** Decide where production events go (stay logging-only vs vendor); document in `ANALYTICS.md` or `DECISIONS.md`.
- **DoD:** Decision recorded; if “vendor”, create a single integration task for Sprint 08.

---

## Stretch (only if Gate 0 + committed work are green)

- MIGRATION-PLAN S07 **Phase C** cleanup: reduce reliance on duplicate local caches for signed-in users (optional).
- Draft **A/B** or onboarding experiment note (`EXP-01` from Sprint 06).

## Out of scope

- Net-new social/subscription features.
- Large schema changes without migration review.

## Demo / review (end of sprint)

- Show completed `OPS-DB02-ROLLOUT.md` + QA sync results.
- Show i18n review status.
- Show perf/obs one-pager.
- Confirm Sprint 08 focus: launch execution vs depth features.

## Retro prompts

- What sync edge case did we miss in planning?
- Was the ops checklist the right granularity?
- What should be automated before App Store submission?
