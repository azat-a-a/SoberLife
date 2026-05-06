# TestFlight Upload Checklist (Manual ASC Step)

Date: 2026-05-06
Owner: @azat

## Preconditions
- [x] Archive exists: `ios/build/SoberLife.xcarchive`
- [x] Release notes template ready: `ios/TESTFLIGHT-RELEASE-NOTES-TEMPLATE.md`
- [x] Rollback playbook ready: `ios/TESTFLIGHT-ROLLBACK.md`

## Xcode Organizer Upload
1. Open Xcode -> Window -> Organizer.
2. Select `SoberLife` archive (latest).
3. Click **Distribute App** -> **App Store Connect** -> **Upload**.
4. Complete signing/export compliance prompts.
5. Confirm build appears in App Store Connect -> TestFlight.

## TestFlight Distribution
1. Open App Store Connect -> TestFlight.
2. Select uploaded build.
3. Assign internal tester group.
4. Paste release notes based on `ios/TESTFLIGHT-RELEASE-NOTES-TEMPLATE.md`.
5. Save and confirm testers can install.

## Completion Record
- Uploaded build number: `confirmed by owner`
- Tester group(s): `configured (internal)`
- Release notes posted: `yes`
- Completed at (UTC+3): `2026-05-06 15:29`

