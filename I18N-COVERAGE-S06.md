# Localization coverage (I18N-03)

Date: 2026-05-06

## Bundles in `SoberLifeAppShell`

| Code | Region / script | Profile picker |
|------|-----------------|----------------|
| `en` | English (default) | English |
| `ru` | Russian | Русский |
| `de` | German | Deutsch |
| `fr` | French | Français |
| `es` | Spanish | Español |
| `it` | Italian | Italiano |
| `pl` | Polish | Polski |
| `zh-Hans` | Chinese (Simplified) | 简体中文 |
| `th` | Thai | ไทย |
| `ja` | Japanese | 日本語 |

## Fallback policy

- **System language:** iOS resolves the best `*.lproj` match; unknown locales fall back per Apple rules (typically toward English).
- **In-app override:** `LocalizationSettings` maps each `AppLanguage` to a bundle folder name (`zh-Hans` for Simplified Chinese). Keys always mirror `en.lproj` so missing strings should not appear when templates stay in sync.

## Maintenance workflow

1. Edit or add keys in `Sources/SoberLifeAppShell/Resources/en.lproj/Localizable.strings` (and `ru.lproj` for parity if needed).
2. Update the corresponding line in each `scripts/i18n/<locale>.txt` (same line order as English keys — one line per key, UTF-8).
3. Regenerate merged files:
   - `python3 scripts/i18n/make_bundle.py`
   - `python3 scripts/i18n/merge_lproj.py`
4. Run `swift test` and smoke the Profile language picker plus Auth, Home, Stats, Chat, SOS on at least one new locale.

## Safety-critical keys (native review recommended before App Store)

- `empathy.sos.crisis.*`, `empathy.relapse.*`, `sos.*`, `auth.error.*`, notification bodies.

## QA status

- Automated: `swift test` passed after adding bundles.
- Manual: run language smoke per locale on simulator/device (checklist: same as `ios/README.md` localization section, extended for new languages).
