# Architecture and Product Decisions

## Decision Log Format
- Date:
- ID:
- Decision:
- Why:
- Impact:
- Status: Proposed | Accepted | Deprecated

---

## 2026-05-05 - D-001
- Decision: Build iOS app with SwiftUI as primary client.
- Why: Fast iteration for native UX, good fit for Apple Sign-In and notifications.
- Impact: iOS-first scope for MVP; Android postponed.
- Status: Accepted

## 2026-05-05 - D-002
- Decision: Use Supabase for Auth, Postgres, Edge Functions, and Storage.
- Why: Single backend platform reduces integration overhead and speeds MVP.
- Impact: Core data model and auth tied to Supabase architecture.
- Status: Accepted

## 2026-05-05 - D-003
- Decision: AI integration through backend proxy (`deepseek-chat` edge function), never direct from client.
- Why: Protect API keys, centralize safety checks, control logging and limits.
- Impact: Slightly higher backend complexity, better security and governance.
- Status: Accepted

## 2026-05-05 - D-004
- Decision: SOS support remains free in all plans.
- Why: Ethical requirement; critical support should not be paywalled.
- Impact: Monetization applies only to convenience/extended features.
- Status: Accepted

## 2026-05-05 - D-005
- Decision: Relapse does not erase full history; app starts a new period while preserving past progress.
- Why: Shame-based resets reduce retention and recovery outcomes.
- Impact: Requires period-based sobriety model and adapted stats logic.
- Status: Accepted

## 2026-05-05 - D-006
- Decision: MVP excludes social feed and groups.
- Why: Focus on highest-impact solo recovery loop first.
- Impact: Faster delivery, lower moderation/privacy burden initially.
- Status: Accepted

## 2026-05-05 - D-010
- Decision: Keep `OnboardingProfile` in AppShell; expose Supabase sync inputs via `SobrietyProfileSnapshot` in `SoberLifeCore`.
- Why: `SoberLifeAppShell` depends on `SoberLifeCore`, not the reverse; sync helpers must not reference app-layer models.
- Impact: Thin mapping (`OnboardingProfile.sobrietySnapshot`) at call sites; Core stays reusable and testable.
- Status: Accepted

## 2026-05-05 - D-011
- Decision: Treat PostgREST **401** as “session no longer valid”: clear auth state, set user-facing re-sign-in copy, do not swallow the error on critical cloud paths (sync, chat history, profile ensure).
- Why: Silent failures strand users with broken RLS and unexplained empty state; explicit re-auth is safer and easier to support.
- Impact: User may see sign-in screen after expiry; local data remains; placeholder auth still skips real JWT paths without error spam.
- Status: Accepted

## 2026-05-05 - D-012
- Decision: Stats “sober periods” timeline is derived from the **current** `sobrietyStartDate` plus `RelapseEvent` history: current row first, closed periods ordered by `occurredAt` descending.
- Why: Matches mental model “now + past chapters”; reuses existing persisted honesty events without a new server table for MVP.
- Impact: UI lists only what is on device (and later synced profile/records); ordering is stable and covered by tests.
- Status: Accepted

## 2026-05-05 - D-013
- Decision: Host the installable iOS client in `ios/` as an Xcode project that depends on the repo-root Swift package (`Package.swift`) via `XCLocalSwiftPackageReference`, rather than converting the whole repo to an Xcode-only layout.
- Why: Keeps `swift build` / `swift test` workflows for Core and AppShell while still delivering a signed app archive from Xcode.
- Impact: Developers open `ios/SoberLife.xcodeproj`; package paths assume the standard layout (`ios` sibling of `Package.swift`).
- Status: Accepted

## Open Decisions
- D-007 Pricing model details for premium limits (message caps, feature gates).
- D-008 Analytics stack selection (self-hosted vs third-party).
- D-009 Localization strategy after RU (EN first or simultaneous rollout).

## Revisit Triggers
- D-006 revisit when D7 retention stabilizes above target.
- D-007 revisit before beta launch.
- D-008 revisit when first 100 beta users are onboarded.

