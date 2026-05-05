# Sprint 01 Plan (2 weeks)

## Sprint Objective
- Build the technical and product foundation so Sprint 02 can focus on user-facing flow without blockers.

## Sprint Dates
- Start: 2026-05-06
- End: 2026-05-19

## Top Priorities
1. Environment and CI setup
2. Supabase schema v1 + RLS
3. iOS app shell and navigation scaffold
4. Compliance baseline (privacy/disclaimer)

## Committed Tasks

### SETUP-01 CI and Project Automation
- Outcome: stable build/test checks on each push.
- Tasks:
  - Configure build workflow.
  - Add test workflow.
  - Add lint/style checks.
- DoD:
  - Failing tests block merge.
  - README includes run instructions.

### ARCH-01 Architecture Baseline
- Outcome: clear app layering and service contracts.
- Tasks:
  - Document SwiftUI module boundaries.
  - Define service interfaces (AuthService, SupabaseService, AIService, NotificationService).
  - Draft edge function contracts.
- DoD:
  - Architecture doc approved by self-review checklist.
  - No major open questions for Sprint 02.

### DB-01 Supabase Schema v1
- Outcome: database ready for onboarding + sobriety core.
- Tasks:
  - Create tables: users, sobriety_records, achievements, ai_conversations.
  - Add indexes and constraints.
  - Add migration scripts.
- DoD:
  - Migrations run cleanly on fresh DB.
  - Basic seed data script works.

### SEC-01 RLS and Access Policies
- Outcome: user can access only their own records.
- Tasks:
  - Enable RLS on all user data tables.
  - Add policies for read/write by `auth.uid()`.
  - Test access denial paths.
- DoD:
  - Positive and negative policy tests documented.
  - No direct cross-user read/write possible.

### IOS-01 App Skeleton
- Outcome: running iOS shell with tabs/navigation and placeholder screens.
- Tasks:
  - App entry, theme, navigation.
  - Placeholder screens: Home, AI Chat, Stats, Profile.
  - Session state and secure token storage skeleton.
- DoD:
  - App launches and navigates across screens.
  - Session state survives app restart (placeholder mode is acceptable).

### CMP-01 Compliance Baseline
- Outcome: legal and safety text integrated in app.
- Tasks:
  - Add medical disclaimer screen.
  - Draft privacy and terms screens.
  - Add emergency contact section placeholder.
- DoD:
  - User can view documents from settings.
  - Required disclaimer appears before AI chat first use.

## Stretch Goals (only if committed work is done)
- OBS-01 Error reporting integration
- PERF-01 Basic cold start measurement

## Out of Scope for Sprint 01
- Full onboarding flow UX polish
- Real AI chat
- SOS flow
- Push notifications
- Social features

## Demo Checklist (End of Sprint)
- Show app shell navigation.
- Show schema migration and RLS tests.
- Show CI passing on latest commit.
- Show legal/disclaimer screens in app.

## Retro Prompts
- What blocked us longest?
- What should be templated to speed up next sprint?
- Which decisions need to be locked before Sprint 02?

