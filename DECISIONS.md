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

## Open Decisions
- D-007 Pricing model details for premium limits (message caps, feature gates).
- D-008 Analytics stack selection (self-hosted vs third-party).
- D-009 Localization strategy after RU (EN first or simultaneous rollout).

## Revisit Triggers
- D-006 revisit when D7 retention stabilizes above target.
- D-007 revisit before beta launch.
- D-008 revisit when first 100 beta users are onboarded.

