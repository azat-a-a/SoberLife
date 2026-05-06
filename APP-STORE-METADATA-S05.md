# App Store Metadata Draft (STORE-01, Sprint 05)

Date: 2026-05-06
Owner: @azat
Status: Draft (review-ready)

## 1) App Store Connect Metadata (EN primary)

### App Name
SoberLife

### Subtitle
Daily support for alcohol-free recovery

### Promotional Text
Build momentum one day at a time. Track sober days, get compassionate AI support, and use SOS tools when cravings hit.

### Keywords
sobriety,recovery,alcohol,sober,counter,habit,wellbeing,tracker,motivation,support

### Description
SoberLife helps you stay alcohol-free with practical daily support and non-judgmental guidance.

What you can do:
- Track your current sober streak and key milestones.
- Log relapse events honestly and continue recovery without losing progress context.
- See meaningful stats like saved money and best streak.
- Get supportive AI chat responses for difficult moments.
- Use SOS tools with grounding steps and quick contact actions.
- Configure daily reminders and quiet hours.

Important:
- SoberLife is a self-help and habit support app.
- It is not a medical device and does not replace professional care.
- In an emergency, call local emergency services immediately.

### App Review Notes (Draft)
- Core audience: adults working on alcohol-free recovery habits.
- Safety context: app includes supportive, non-judgmental copy and emergency guidance in SOS flow.
- Medical boundary: app explicitly states it is not medical advice/treatment.
- Login: standard email/password auth via Supabase.

---

## 2) Localization Metadata Pack (RU draft)

### Subtitle (RU)
Ежедневная поддержка трезвого восстановления

### Promotional Text (RU)
Укрепляйте трезвость день за днем: отслеживайте прогресс, получайте поддерживающие AI-ответы и используйте SOS-инструменты в сложные моменты.

### Description (RU, short draft)
SoberLife помогает поддерживать трезвость: счетчик дней, вехи, статистика, поддерживающий AI-чат, SOS-помощь и напоминания.  
Приложение не является медицинским сервисом и не заменяет помощь специалиста.

---

## 3) Screenshot Plan (iPhone)

Required set (6 shots target):
1. Welcome/Auth screen (clear value proposition)
2. Home with sober day counter + SOS CTA
3. Stats with milestones/saved money
4. SOS flow with grounding actions
5. Profile with reminder + quiet hours settings
6. Language selector in Profile (System/English/Russian)

Screenshot copy principles:
- Keep text calm, supportive, and non-judgmental.
- Avoid claims of cure, treatment, or guaranteed outcomes.
- Keep emergency wording explicit in SOS-related visuals.

---

## 4) Privacy Nutrition Labels (Draft Matrix)

Data linked to user:
- Contact Info: Email Address (account/auth).
- Identifiers: User ID (session/account linkage).
- Usage Data: Feature interaction events (analytics baseline).

Data not collected for third-party tracking (draft intent):
- No ad tracking usage planned in MVP.

Collection purpose mapping (draft):
- App Functionality: auth, profile, sobriety progress.
- Analytics: product usage trends and reliability improvements.

Action before final submit:
- Verify final ASC checkbox selections match current implementation and analytics scope in `ANALYTICS.md`.

---

## 5) Policy-Sensitive Language Validation

Validated wording requirements:
- Medical disclaimer present ("not a medical device / not a substitute for professional care").
- Emergency guidance included (call local emergency services).
- Supportive language style aligned with empathy copy goals.

Mapped to app surfaces:
- Auth/intro messaging: non-judgmental recovery framing.
- SOS flow: crisis disclaimer + immediate help direction.
- Profile/help/legal surface: policy text references.

---

## 6) Launch Checklist Mapping

`LAUNCH-CHECKLIST.md` coverage:
- "App Store metadata finalized" -> draft prepared in this document.
- "Screenshots updated and accurate" -> screenshot plan prepared (capture pending).
- "Privacy nutrition labels verified" -> draft matrix prepared (ASC final selection pending).
- "App Review notes include safety/disclaimer context" -> draft section prepared.

No blocker gaps identified for moving to final metadata review.

