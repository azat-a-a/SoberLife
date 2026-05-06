# TestFlight Rollback Playbook

## Trigger
Rollback/disable distribution if any of the following occurs:
- P0 safety or data-loss defect
- Widespread auth/sign-in failure
- Critical crash regression in core flow

## Immediate Actions
1. Pause external rollout / stop adding testers to affected build.
2. Notify team channel with incident summary and impacted build number.
3. Tag issue severity and assign incident owner.

## Containment
- If a safer previous build exists, make it primary for new testers.
- Remove affected build from active tester groups where possible.
- Publish "Known issue" note in tester communication.

## Fix Path
1. Branch hotfix from latest stable point.
2. Implement minimal fix.
3. Run focused regression (`swift test` + impacted manual flow).
4. Upload new candidate and validate with internal testers first.

## Closure
- Confirm defect is resolved in replacement build.
- Document root cause and prevention action.
- Update `DECISIONS.md` and `TASKS.md` follow-up items.

