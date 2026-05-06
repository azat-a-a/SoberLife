# SoberLife Analytics Baseline (DATA-01)

## Scope (v1)
This baseline tracks 4 core product events:
- `onboarding_complete`
- `sos_opened`
- `relapse_logged`
- `milestone_unlocked`

Implementation uses an in-app tracker (`AnalyticsTracker`) with a logging sink (`LoggingAnalyticsSink`) as a provider stub.

## Event Schema
Each event has:
- `name` (string)
- `timestamp` (generated client-side)
- `properties` (`[String: String]`)

Current properties by event:

### `onboarding_complete`
- `goal_selected`: `true|false`
- `daily_cost_provided`: `true|false`
- `notifications_enabled`: `true|false`

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
- milestone: `milestone_unlocked.<userID>.<days>`

`sos_opened` and `relapse_logged` are intentional action events and fire on each user action.

## Instrumented Locations
- `OnboardingState.complete()` -> `onboarding_complete`
- `HomeView` SOS button tap -> `sos_opened`
- `HomeView` relapse confirmation action -> `relapse_logged`
- `StatsState.load()` when new milestones appear -> `milestone_unlocked`

## Next Step (post-baseline)
- Replace `LoggingAnalyticsSink` with a real provider (e.g. Supabase event table, PostHog, Amplitude) without changing call sites.
