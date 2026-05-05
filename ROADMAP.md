# SoberLife Roadmap (MVP -> v1.1)

## Product Goal
- Help users maintain sobriety with daily tracking, non-judgmental AI support, and safe relapse recovery flow.

## Success Metrics
- D1 retention >= 45%
- D7 retention >= 25%
- 7-day milestone reach rate >= 35%
- SOS usage-to-return rate (opens app again within 24h) >= 60%
- Crash-free sessions >= 99%

## Core Principles
- No shame, no blame language.
- SOS support is always free.
- User privacy is first-class.
- App does not replace professional medical help.

## Phase Plan

### Phase 0: Foundation (Week 1)
**Goals**
- Set up repository workflow and environments.
- Finalize MVP scope and compliance baseline.

**Deliverables**
- CI pipeline for build and tests.
- Environment config for dev/stage/prod.
- Privacy Policy, Terms, and medical disclaimer draft.
- Initial architecture and API contracts.

### Phase 1: Auth + Onboarding (Week 2)
**Goals**
- Get user from install to active home screen in under 2 minutes.

**Deliverables**
- Apple Sign-In integration.
- Minimal onboarding (3-4 screens).
- Sobriety start date and daily alcohol cost saved.
- Notification permissions screen.

### Phase 2: Sobriety Core (Weeks 3-4)
**Goals**
- Provide high-confidence day counter and meaningful progress.

**Deliverables**
- Home screen with sobriety day counter.
- Milestone progress (7, 30, 90, 365 days).
- Basic stats (current streak, saved money).
- Achievement unlock logic.

### Phase 3: AI Chat + SOS (Weeks 5-6)
**Goals**
- Deliver reliable, empathetic support in critical moments.

**Deliverables**
- DeepSeek chat via Supabase Edge Function.
- SOS one-tap support flow.
- Safety prompts and emergency hotline fallback.
- Chat history storage and basic context injection.

### Phase 4: Reliability + Push (Week 7)
**Goals**
- Improve engagement and reduce drop-off.

**Deliverables**
- Daily motivational push notifications.
- Milestone and re-engagement notifications.
- Notification preferences + quiet hours.
- Error monitoring and latency dashboards.

### Phase 5: Beta + Release (Weeks 8-9)
**Goals**
- Reach TestFlight quality and release confidence.

**Deliverables**
- End-to-end smoke tests on real devices.
- Bugfix pass (no P0/P1 open).
- App Store assets and metadata.
- Rollback and release checklist.

## Post-MVP (v1.1+)
- Friends and private support feed.
- Journal and trigger tracking.
- Group support features.
- Content library and guided exercises.
- Optional freemium limits (never blocking SOS/basic support).

## Risks and Mitigations
- AI unsafe responses -> safety guardrails + fallback templates.
- Relapse flow stigma -> UX copy review and non-judgment checks.
- Notification fatigue -> defaults conservative, user controls.
- Scope creep -> freeze MVP after Week 2.

