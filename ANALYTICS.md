# SoberLife Analytics Baseline (DATA-01)

## Scope (v1)
This baseline tracks core behavioral + funnel events:
- Funnel: `auth_started`, `auth_success`, `onboarding_complete`, `active_use_24h`
- Behavioral: `sos_opened`, `relapse_logged`, `milestone_unlocked`

Implementation uses an in-app tracker (`AnalyticsTracker`) with a logging sink (`LoggingAnalyticsSink`) as a provider stub.

## Event Schema
Each event has:
- `name` (string)
- `timestamp` (generated client-side)
- `properties` (`[String: String]`)

Current properties by event:

### `auth_started`
- `method`: currently `email_password_signin|email_password_signup`

### `auth_success`
- `method`: currently `email_password_signin|email_password_signup`

### `onboarding_complete`
- `goal_selected`: `true|false`
- `daily_cost_provided`: `true|false`
- `notifications_enabled`: `true|false`

### `active_use_24h`
- `surface`: currently `main_tabs`

### `sos_opened`
- `source`: currently `home`

### `relapse_logged`
- `source`: currently `home_truth_button`
- `previous_streak_days`: integer-as-string

### `milestone_unlocked`
- `milestone_days`: integer-as-string
- `current_streak_days`: integer-as-string

## Duplicate Prevention
`AnalyticsTracker.trackOnce` stores dedupe keys in `UserDefaults`:
- onboarding: `onboarding_complete.<userID>`
- active use: `active_use_24h.<userID>.<yyyy-mm-dd>`
- milestone: `milestone_unlocked.<userID>.<days>`

`auth_started`, `auth_success`, `sos_opened`, and `relapse_logged` are intentional action events and fire on each user action.

## Instrumented Locations
- `SignedOutPlaceholderView` sign-in/sign-up tap -> `auth_started`
- `SessionState.signIn()` / `signUp()` success -> `auth_success`
- `OnboardingState.complete()` -> `onboarding_complete`
- `MainTabView` first open per day -> `active_use_24h`
- `HomeView` SOS button tap -> `sos_opened`
- `HomeView` relapse confirmation action -> `relapse_logged`
- `StatsState.load()` when new milestones appear -> `milestone_unlocked`

## Next Step (post-baseline)
- Replace `LoggingAnalyticsSink` with a real provider (e.g. Supabase event table, PostHog, Amplitude) without changing call sites.
