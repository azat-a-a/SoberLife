# Sprint 03 Plan (2 weeks)

## Sprint Objective
- Launch reliable AI support and one-tap SOS flow so users can get immediate, empathetic help during cravings and difficult moments.

## Sprint Dates
- Start: 2026-06-03
- End: 2026-06-16

## Top Priorities
1. DeepSeek integration through secure Edge Function
2. AI chat screen with persistent conversation history
3. SOS crisis flow from Home in one tap
4. Safety guardrails and hotline fallback

## Committed Tasks

### AI-01 Edge Function `deepseek-chat`
- Outcome: backend endpoint returns safe, context-aware AI responses.
- Tasks:
  - Implement Supabase Edge Function proxy for DeepSeek API.
  - Add system prompt with non-judgmental support style.
  - Inject minimal user context (sober days, recent triggers, recent journal notes if available).
  - Add timeout/retry and safe error handling.
- DoD:
  - API key is never exposed in iOS client.
  - 90th percentile response time <= 5s on stage target.
  - Logs exclude sensitive raw user content where possible.
  - Function contract documented.

### AI-02 Chat UI (v1)
- Outcome: user can send messages and receive AI responses in near real-time.
- Tasks:
  - Build chat screen with message list and input area.
  - Add loading, retry, and offline error states.
  - Save conversation to `ai_conversations`.
  - Support conversation types: `chat`, `sos`, `daily`.
- DoD:
  - New chat starts and messages persist after app restart.
  - Failed request can be retried from UI.
  - Conversation type is correctly stored and queryable.

### SOS-01 One-Tap SOS Flow
- Outcome: user receives immediate help from Home when urge is strong.
- Tasks:
  - Add SOS button on Home.
  - Open dedicated SOS chat context with prefilled supportive first response.
  - Add quick actions: breathing exercise, call trusted contact (placeholder), log trigger.
- DoD:
  - SOS is reachable from Home in 1 tap.
  - First SOS response appears within 3s target (stage).
  - Quick actions are usable without leaving SOS context.

### SAFE-01 Safety Guardrails
- Outcome: unsafe situations are handled with clear fallback and emergency guidance.
- Tasks:
  - Add risk keyword/intent detection on backend response path.
  - Add emergency hotline and urgent help card in high-risk cases.
  - Add refusal behavior for harmful requests while staying supportive.
  - Create safety test prompts checklist.
- DoD:
  - High-risk prompts always show emergency guidance.
  - Harmful instructions are not provided by AI.
  - Safety checks pass for agreed test scenarios.

### COPY-01 Empathy and Tone Review
- Outcome: all AI and UI copy remains supportive and non-shaming.
- Tasks:
  - Review prompt templates and fallback messages.
  - Review SOS microcopy and crisis labels.
  - Replace any punitive or judgmental phrasing.
- DoD:
  - Tone checklist completed and approved.
  - No shaming language in user-facing strings.

### QA-01 End-to-End Smoke for AI + SOS
- Outcome: confidence to move forward with notifications and relapse flow in Sprint 04.
- Tasks:
  - Test core scenario: Home -> Chat -> SOS -> fallback.
  - Validate conversation persistence and type tagging.
  - Validate failure modes (timeout/network issue/API error).
- DoD:
  - Smoke checklist passed on simulator and real device.
  - No open P0/P1 defects at sprint close.

## Stretch Goals (if all committed work is done)
- AI-03 Daily affirmation generation and scheduling stub.
- OBS-01 Add latency/error dashboard for `deepseek-chat`.
- UX-01 SOS quick action for opening breathing timer overlay.

## Out of Scope for Sprint 03
- Full relapse ("truth button") flow
- Push notification scheduling
- Social feed/friends
- Subscription/paywall

## Demo Checklist (End of Sprint)
- Show regular AI chat with persisted history.
- Show SOS path from Home and quick actions.
- Show high-risk fallback with hotline guidance.
- Show timeout/error handling and retry flow.

## Retro Prompts
- Which AI responses felt most useful vs generic?
- Where did latency hurt user trust?
- What safety gaps must be closed before wider beta?

