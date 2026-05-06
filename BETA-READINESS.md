# Closed Beta Readiness Gate (BETA-01)

## Date
- 2026-05-06

## Goal
Establish a clear go/no-go gate for invited TestFlight users so scope, quality, and incident response are controlled before broader rollout.

## 1) Beta Entry Criteria

### Product / Scope
- [x] MVP scope is frozen for beta window.
- [x] Out-of-scope list is explicit and shared.
- [x] Core journeys are stable and verified: Auth, Onboarding, Home, AI Chat, SOS, Relapse, Notifications.

### Quality / Safety
- [x] No open P0 issues.
- [x] Any P1 has owner, ETA, and mitigation documented.
- [x] SOS/emergency and non-judgment copy validated in beta build.
- [x] Manual smoke complete on simulator + real iPhone.

### Technical Readiness
- [x] CI green on beta candidate branch.
- [x] Crash/error monitoring active and reviewed.
- [x] Edge function and app secrets configured for beta environment.
- [x] DB migrations and RLS policies validated.

### Release Operations
- [x] TestFlight upload path verified.
- [x] Tester groups prepared.
- [x] Beta release notes template ready.
- [x] Rollback and hotfix path documented.

## 2) Scope Freeze (Beta Window)

### In Scope
- Stabilization, bug fixes, QA, observability.
- Release process hardening (TestFlight + notes + rollback).
- Required launch metadata/content prep.
- Language override in Profile (`I18N-02`) with smoke validation.

### Out of Scope
- Social/group features.
- Monetization/paywall.
- Large architecture refactors.
- Broad new feature additions unrelated to beta readiness.

## 3) Candidate Build Definition
- Candidate source: latest `main` commit passing CI and smoke.
- Versioning: `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` bumped for TestFlight upload.
- Candidate tag format: `beta-candidate-YYYYMMDD-N`.

### Candidate Metadata (fill before go/no-go)
- Candidate commit SHA: local-uncommitted (pending release commit)
- Candidate tag: TBD (set on release candidate commit)
- Upload date/time: 2026-05-06 (completed, see `ios/TESTFLIGHT-UPLOAD-CHECKLIST.md`)
- Owner: @azat

## 4) Known Limitations (to share with testers)
- `markdown-lint` CI job may remain queued in some runs; engineering validation continues via `swift-build-and-test` + `ios-xcodebuild`.
- Language coverage currently includes EN/RU, with in-app override in Profile (`System/English/Russian`).
- International language expansion (EU/CN/TH/JP) is planned in Sprint 06 (`I18N-03`).

## 5) Go/No-Go Decision
- Decision: [x] GO / [ ] NO-GO
- Date: 2026-05-06
- Decision owner(s): @azat
- Notes: Manual TestFlight distribution completed and monitoring review confirmed; closed beta gate approved.

