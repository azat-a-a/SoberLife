# Supabase -> Yandex Mapping Matrix

This matrix maps current Supabase-dependent behaviors to the target Yandex Cloud API so iOS adapter migration can be done file-by-file.

## Auth

- `POST /auth/v1/token?grant_type=password` -> `POST /auth/signin`
- `POST /auth/v1/signup` -> `POST /auth/signup`
- Supabase session restore (`currentSession`) -> local persisted session + `POST /auth/refresh`
- Supabase signout semantics -> `POST /auth/signout`

## Profile / User ensure

- `RPC ensure_user_profile` -> `GET /v1/profile` (404 => create path) or explicit upsert endpoint
- `PATCH /rest/v1/users` -> `PATCH /v1/profile`

## Sobriety sync

- `POST/PATCH /rest/v1/sobriety_records` -> `POST /v1/sobriety/onboarding-sync` and `POST /v1/sobriety/relapse`
- `SELECT sobriety_records` for timeline hydrate -> `GET /v1/sobriety/history`

## Achievements

- `SELECT achievements` -> `GET /v1/achievements`
- `UPSERT achievements (merge-duplicates)` -> `POST /v1/achievements/milestones`

## Settings / contacts

- `notification_preferences` table select/upsert -> `GET /v1/settings` + `PUT /v1/settings/notification-preferences`
- `support_contacts` table select/upsert -> `GET /v1/settings` + `PUT /v1/settings/support-contact`

## AI conversations

- `SELECT ai_conversations` -> `GET /v1/ai/conversations?limit=40`
- `INSERT ai_conversations` -> `POST /v1/ai/conversations`
- `UPDATE ai_conversations.messages` -> `PUT /v1/ai/conversations/{id}`

## Community pulse

- `RPC community_checkin` -> `POST /v1/community/checkin`
- `RPC community_pulse_last7` -> `GET /v1/community/pulse?days=7`

## Edge functions

- `POST /functions/v1/deepseek-chat` (Supabase Edge Function proxy) -> Yandex backend AI proxy endpoint (recommended: `POST /v1/ai/reply`)

## iOS adapter touchpoints (current files)

- `Sources/SoberLifeCore/HTTPSupabaseService.swift`
  - Replace with backend HTTP client abstraction that targets Yandex endpoints.
- `Sources/SoberLifeCore/SupabaseAuthService.swift`
  - Replace with `YandexAuthService`.
- `Sources/SoberLifeAppShell/SobrietyCloudSync.swift`
  - Replace Supabase sync calls with Yandex sobriety endpoints.
- `Sources/SoberLifeAppShell/UserSettingsCloudSync.swift`
  - Replace table sync calls with settings endpoints.
- `Sources/SoberLifeAppShell/AchievementsCloudSync.swift`
  - Replace milestone push/bootstrap calls with achievements endpoints.
- `Sources/SoberLifeAppShell/AIChatState.swift`
  - Replace conversation load/save with Yandex AI conversation APIs.
- `Sources/SoberLifeAppShell/CommunityPulse.swift`
  - Replace RPC names with Yandex community endpoints.

## Rollout strategy notes

- Keep app-level models and UI state objects stable.
- Swap only transport adapters first (contract parity).
- Gate rollout with runtime config flag (`backend_mode = supabase|yandex`) during canary.
- Remove Supabase-specific code only after production burn-in window.

