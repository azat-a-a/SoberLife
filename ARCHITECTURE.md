# SoberLife Architecture Baseline (ARCH-01)

## Goal
- Define a clear MVP architecture so feature work can proceed without structural blockers.

## Principles
- Keep iOS app modular and testable (protocol-first).
- Isolate external dependencies (Supabase, DeepSeek, APNs) behind service interfaces.
- Keep business logic in `Domain` and avoid putting logic in views.
- Design for privacy and least-privilege data access from day one.

## Layered Structure

### Presentation (SwiftUI)
- Scope:
  - Screens, navigation, view models, UI state.
  - User interaction mapping to domain use-cases.
- Rules:
  - No direct API/database calls from views.
  - Uses `Domain` protocols only.

### Domain
- Scope:
  - Use-cases and core rules (sobriety counter, milestones, relapse behavior).
  - Entities and value objects shared across app modules.
- Rules:
  - No framework-specific code (UI/network/storage).
  - Deterministic and easy to unit test.

### Data
- Scope:
  - Repository implementations and remote/local data sources.
  - Supabase client integration, edge function calls, push scheduling adapters.
- Rules:
  - Implements interfaces defined by `Domain`.
  - Handles mapping between transport and domain models.

## Service Interfaces (Protocol-First)

- `AuthService`
  - Sign in, sign up, sign out, and session retrieval.
  - Implemented with Supabase Auth **email/password** (`HTTPSupabaseService` calls `/auth/v1/token` and `/auth/v1/signup`); JWT is cached for PostgREST / RLS.

- `SupabaseService`
  - Generic gateway for table operations and edge function invocation.
  - Central place for auth token propagation and request-level concerns.

- `AIService`
  - Sends user message/context to `deepseek-chat`.
  - Supports modes: `chat`, `sos`, `daily`, `analysis`.

- `NotificationService`
  - Manages push permission, scheduling, and preference sync.
  - Supports categories: daily, milestone, re-engagement.

## Edge Function Contracts (Draft)

### `deepseek-chat`
- Request:
  - `userId: UUID`
  - `conversationType: "chat" | "sos" | "daily" | "analysis"`
  - `messages: [{ role: "user" | "assistant" | "system", content: String, timestamp: ISO8601 }]`
  - `context: { soberDays?: Int, recentTriggers?: [String], recentJournalNotes?: [String] }`
- Response:
  - `reply: String`
  - `suggestedActions?: [String]`
  - `riskFlags?: [String]`

### `calculate-stats`
- Request:
  - `userId: UUID`
  - `dailyAlcoholCost?: Decimal`
- Response:
  - `currentStreakDays: Int`
  - `lifetimeSoberDays: Int`
  - `savedMoney: Decimal`
  - `nextMilestoneDays: Int`
  - `progressToMilestone: Double`

### `send-notifications`
- Request:
  - `userId: UUID`
  - `category: "daily" | "milestone" | "reengagement"`
  - `payload: { title: String, body: String, deepLink?: String }`
  - `scheduledAt?: ISO8601`
- Response:
  - `accepted: Bool`
  - `messageId?: String`

## Initial Module Map (Current Repository)
- `Sources/SoberLifeCore`
  - Domain primitives and service protocols.
  - Shared use-cases (e.g., sobriety calculations).
- `Tests/SoberLifeCoreTests`
  - Domain and service-contract tests.

## Next Implementation Steps
- Add repository protocols in `Domain`.
- Add data mappers and DTOs in `Data`.
- Build app shell module for `Presentation` (SwiftUI screens + navigation).
- Add Supabase-backed implementations behind service protocols.

