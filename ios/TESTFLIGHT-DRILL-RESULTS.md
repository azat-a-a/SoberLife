# TestFlight Drill Results (REL-01)

Date: 2026-05-06
Owner: @azat

## Scope
- Validate repeatable archive flow using `ios/scripts/testflight_archive.sh`.
- Run one rollback drill in tabletop mode using `ios/TESTFLIGHT-ROLLBACK.md`.

## Results
- Archive script run: PASS
  - Command: `bash ios/scripts/testflight_archive.sh`
  - Result: `** ARCHIVE SUCCEEDED **`
  - Artifact: `ios/build/SoberLife.xcarchive`
- Rollback drill (tabletop): PASS
  - Scenario: critical regression after beta publish
  - Verified actions: pause rollout, incident notification, stable build fallback, hotfix path, closure checklist

## Notes
- Follow-up fix completed after initial drill:
  - Added `UIRequiresFullScreen=true` in `ios/App/Info.plist`.
  - Re-ran archive validation successfully with no orientation warning.

## REL-01 Exit Criteria Status
- Archive produced by script: DONE
- Release notes template prepared: DONE (`ios/TESTFLIGHT-RELEASE-NOTES-TEMPLATE.md`)
- Rollback drill executed once: DONE (tabletop)
- Build distributed to TestFlight tester group: PENDING (manual App Store Connect step)

