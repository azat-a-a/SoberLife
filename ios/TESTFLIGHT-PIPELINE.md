# TestFlight Pipeline (REL-01)

## Goal
Provide a repeatable path to produce and distribute a beta build.

## Preconditions
- Xcode signing is configured (Team, Bundle ID, capability set).
- App Store Connect app exists for the bundle identifier.
- Marketing icon (1024x1024) is set in `AppIcon`.
- Secrets for release build are configured (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).

## 1) Build and Archive
From repository root:

```bash
bash ios/scripts/testflight_archive.sh
```

Archive output is placed under:
- `ios/build/SoberLife.xcarchive`

## 2) Distribute to TestFlight
Two supported paths:

### A. Xcode Organizer (recommended)
1. Open Xcode Organizer.
2. Select the latest `SoberLife` archive.
3. Choose **Distribute App** -> **App Store Connect** -> **Upload**.
4. Complete export compliance prompts.

### B. CI/automation path
Use your CI lane/tooling to upload the generated archive artifact with App Store Connect credentials.
Keep release notes generated from `ios/TESTFLIGHT-RELEASE-NOTES-TEMPLATE.md`.

## 3) Post-upload checklist
- Build processed in TestFlight.
- Assigned to internal tester group.
- Release notes attached.
- Known limitations section updated (if needed).

