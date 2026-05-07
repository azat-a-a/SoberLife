# Design Notes (Calm UI)

Last updated: 2026-05-07

## Goal

Create a calm, supportive interface that lowers stress and keeps attention on recovery actions.

## Visual language

- Tone: cool-zen, soft, spacious, non-clinical.
- Priority: readability first, emotion second, decoration last.
- Surfaces should feel light and quiet, never loud or urgent by default.

## Source of truth in code

- Theme tokens and helpers live in `Sources/SoberLifeAppShell/CalmTheme.swift`.
- Reusable primitives:
  - `CalmPrimaryButtonStyle`
  - `CalmSecondaryButtonStyle`
  - `calmCard()`
  - `calmPageBackground()`
  - `calmSectionTitle()`
  - `calmSecondaryText()`

Always use these primitives before introducing one-off styling.

## Color and contrast rules

- Primary accent: calm teal (`CalmTheme.accent`).
- SOS / warning accent: soft terracotta (`CalmTheme.sos`) only for cautionary context.
- Use `calmSecondaryText()` for helper text to avoid harsh contrast.
- Error/warning containers must be softened (rounded container + low-opacity tint), not bright warning stripes.

## Typography

- Prefer rounded headings for key emotional surfaces (Onboarding, SOS, core section headers).
- Keep body text at default dynamic type sizes.
- Avoid all-caps labels for primary actions.

## Spacing system

- Base rhythm: 8pt grid.
- Card inner padding: 16.
- Standard vertical groups: 8 / 16 spacing steps.
- Avoid dense stacking of controls; maintain breathing room around primary actions.

## Motion and haptics

- Use subtle easing only (`CalmTheme.breatheAnimation`).
- Motion should communicate continuity, not excitement.
- Haptics should be quiet and semantic:
  - `.selection` for lightweight feedback (chat/send/load transitions).
  - `.impact` for opening key support surfaces (SOS sheet).
  - `.warning` for relapse confirmation.
  - `.success` for positive completion (AI reply/fallback resolution).

No repetitive or high-intensity haptic patterns.

## Component behavior

- Primary CTA: `CalmPrimaryButtonStyle`.
- Secondary CTA: `CalmSecondaryButtonStyle`.
- Informational groups: `calmCard()`.
- Chat bubbles stay in soft accents; avoid saturated blues/reds.
- Progress indicators should use calm accent tints.

## Content tone alignment

- Use empathetic, non-judgmental language in microcopy.
- Prefer supportive verbs: "continue", "breathe", "pause", "try again".
- Avoid alarmist wording unless truly safety-critical.

## QA checklist (design)

Before merging UI work:

- [ ] No hardcoded harsh colors for warnings/errors.
- [ ] New screens use `CalmTheme` tokens and helpers.
- [ ] Spacing follows 8pt rhythm.
- [ ] Secondary text uses softened contrast where appropriate.
- [ ] Key flows still pass accessibility and readability checks.
- [ ] Animations and haptics feel subtle on device.

