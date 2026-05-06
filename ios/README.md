# SoberLife iOS app (Xcode)

## Open and run
1. Open `SoberLife.xcodeproj` in Xcode (16+ recommended).
2. Set your **Team** on the `SoberLife` target (Signing & Capabilities).
3. In the Supabase dashboard, enable **Email** under **Authentication → Providers** (and adjust sign-up / email confirmation to match how you want onboarding to behave).
4. Configure Supabase for real auth/chat:
   - Either edit **Build Settings** → User-Defined: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
   - Or copy `Config/Secrets.example.xcconfig` to **`Config/Secrets.xcconfig`** (gitignored), put secrets there, and set **Based on Configuration File** for Debug/Release to that file.
5. Add a **1024×1024** icon under `App/Assets.xcassets/AppIcon` before archiving for TestFlight (App Store Connect rejects missing marketing icon).

The app signs in with **email and password** via Supabase Auth (`/auth/v1/token` password grant and `/auth/v1/signup`). There is no Sign in with Apple entitlement in this target.

## Command-line build (Simulator)
From repo root:

```bash
cd ios
xcodebuild -project SoberLife.xcodeproj -scheme SoberLife \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

Pick any installed simulator from **Xcode → Window → Devices and Simulators**.

## Localization workflow
`SoberLifeAppShell` uses package resources under `Sources/SoberLifeAppShell/Resources/*.lproj/Localizable.strings`.

Shipped locales: `en`, `ru`, `de`, `fr`, `es`, `it`, `pl`, `zh-Hans`, `th`, `ja` (see `I18N-COVERAGE-S06.md`).

**System language:** With Profile set to **System**, strings load from the packaged `.lproj` that best matches `Locale.preferredLanguages` (SwiftPM’s `Bundle.module` does not reliably follow the OS if you only call `NSLocalizedString`). The app `Info.plist` lists supported languages via `CFBundleLocalizations`.

Rules for adding/changing copy:
1. Add or update the key in `en.lproj/Localizable.strings` (source of truth for key order).
2. Update `ru.lproj` and each `scripts/i18n/<locale>.txt` line (same order as English — one translation per line).
3. Regenerate merged bundles from repo root:
   - `python3 scripts/i18n/make_bundle.py`
   - `python3 scripts/i18n/merge_lproj.py`
4. Use `L10n.text("key")` in SwiftUI views or `L10n.string("key")` / `L10n.format("key", ...)` in non-view code.
5. Avoid new hardcoded user-facing strings in views/services.

Validation:
- Run `swift test`.
- In simulator, use Profile → App language and verify core screens (Auth, Home, Chat, Stats, Profile, SOS) for any locale you changed.

## TestFlight pipeline (REL-01)
1. Create an App ID + App in App Store Connect matching **Bundle Identifier** (`com.soberlife.app` by default, change in target settings if needed).
2. Build archive from repo root:

```bash
bash ios/scripts/testflight_archive.sh
```

3. Upload via Xcode Organizer (**Distribute App** -> **App Store Connect** -> **Upload**) and complete export compliance prompts.
4. Fill tester-facing notes using `ios/TESTFLIGHT-RELEASE-NOTES-TEMPLATE.md`.
5. If a bad build is shipped, follow `ios/TESTFLIGHT-ROLLBACK.md`.
6. Complete manual ASC upload/distribution checklist in `ios/TESTFLIGHT-UPLOAD-CHECKLIST.md`.

Reference runbook: `ios/TESTFLIGHT-PIPELINE.md`.

The Swift package at the repo root (`Package.swift`) is linked as a **local Swift Package** (`relativePath = ..` from this `ios` folder).
