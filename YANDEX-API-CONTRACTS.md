# Yandex Backend API Contracts (MVP-Compatible)

This document defines minimal backend contracts required to replace current Supabase-backed behaviors without changing user-visible flows.

## Conventions

- Base URL: `https://<your-api-domain>`
- Auth header: `Authorization: Bearer <access_token>`
- Content type: `application/json`
- Time format: ISO-8601 UTC
- Error shape:

```json
{
  "code": "string_code",
  "message": "human readable message"
}
```

## 1) Auth

### `POST /auth/signup`

Request:

```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

Response `200`:

```json
{
  "user_id": "uuid",
  "access_token": "jwt",
  "refresh_token": "opaque-or-jwt",
  "expires_in": 3600
}
```

### `POST /auth/signin`

Request: same as signup.

Response `200`: same as signup.

### `POST /auth/refresh`

Request:

```json
{
  "refresh_token": "token"
}
```

Response `200`:

```json
{
  "access_token": "jwt",
  "refresh_token": "rotated-token",
  "expires_in": 3600
}
```

### `POST /auth/signout`

Request:

```json
{
  "refresh_token": "token"
}
```

Response `204` (or `200` with empty JSON).

## 2) User Profile

### `GET /v1/profile`

Response `200`:

```json
{
  "id": "uuid",
  "sobriety_start_date": "2026-05-01T00:00:00Z",
  "daily_alcohol_cost": 850.0
}
```

### `PATCH /v1/profile`

Request:

```json
{
  "sobriety_start_date": "2026-05-01T00:00:00Z",
  "daily_alcohol_cost": 850.0
}
```

Response `204`.

## 3) Sobriety Records

### `GET /v1/sobriety/history`

Response `200`:

```json
{
  "current_start_date": "2026-05-01T00:00:00Z",
  "records": [
    {
      "start_date": "2026-04-01T00:00:00Z",
      "end_date": "2026-04-20T10:00:00Z"
    }
  ]
}
```

### `POST /v1/sobriety/onboarding-sync`

Request:

```json
{
  "sobriety_start_date": "2026-05-01T00:00:00Z",
  "daily_alcohol_cost": 850.0
}
```

Response `204`.

### `POST /v1/sobriety/relapse`

Request:

```json
{
  "new_period_start": "2026-05-07T00:00:00Z",
  "occurred_at": "2026-05-07T10:11:12Z"
}
```

Response `204`.

## 4) Achievements

### `GET /v1/achievements`

Response `200`:

```json
{
  "milestones": ["milestone_7", "milestone_30"]
}
```

### `POST /v1/achievements/milestones`

Request:

```json
{
  "types": ["milestone_90"]
}
```

Response `204`.

## 5) Settings + Support Contact

### `GET /v1/settings`

Response `200`:

```json
{
  "notification_preferences": {
    "daily_enabled": true,
    "milestone_enabled": true,
    "reengagement_enabled": true,
    "daily_reminder_hour": 10,
    "daily_reminder_minute": 0,
    "quiet_hours_start": 22,
    "quiet_hours_end": 8
  },
  "support_contact": {
    "trusted_name": "Alex",
    "trusted_phone": "+70000000000"
  }
}
```

### `PUT /v1/settings/notification-preferences`

Request: same object as `notification_preferences`.

Response `204`.

### `PUT /v1/settings/support-contact`

Request:

```json
{
  "trusted_name": "Alex",
  "trusted_phone": "+70000000000"
}
```

Response `204`.

## 6) AI Conversations

### `GET /v1/ai/conversations?limit=40`

Response `200`:

```json
{
  "items": [
    {
      "id": "uuid",
      "conversation_type": "chat",
      "created_at": "2026-05-07T10:00:00Z",
      "messages": []
    }
  ]
}
```

### `POST /v1/ai/conversations`

Request:

```json
{
  "conversation_type": "chat",
  "messages": []
}
```

Response `201` with created conversation payload.

### `PUT /v1/ai/conversations/{id}`

Request:

```json
{
  "messages": []
}
```

Response `204`.

## 7) Community Pulse (Anonymous)

### `POST /v1/community/checkin`

Request: empty JSON `{}`.

Response `204`.

### `GET /v1/community/pulse?days=7`

Response `200`:

```json
{
  "items": [
    { "day": "2026-05-01", "checkins": 12 },
    { "day": "2026-05-02", "checkins": 9 }
  ]
}
```

## Security Requirements

- Access tokens signed with strong key in Lockbox.
- Refresh token rotation with revocation on signout.
- Ownership checks on every resource by `user_id` from JWT claims.
- Rate limiting on auth and write-heavy endpoints.
- PII minimization in logs (no tokens/passwords).

