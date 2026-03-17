# Beta Release Checklist

## Pre-release validation

- [ ] Sync to the intended release commit.
- [ ] Regenerate the Xcode project: `xcodegen generate`.
- [ ] Run targeted integration coverage:
  - `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingFlowIntegrationTests`
- [ ] Run full test suite:
  - `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS'`

## Manual verification

- [ ] Complete every item in `docs/testing/manual-qa-checklist.md`.
- [ ] Verify one clean idle -> recording -> finalize -> idle pass manually.
- [ ] Confirm no unexpected permission prompts appear after initial grant.
- [ ] Confirm finalized output includes `mixed.m4a`, `system_audio.m4a`, and `mic_audio.m4a`.
- [ ] Confirm MVP scope remains audio-only (no required video artifact).

## Release artifacts

- [ ] Build a release candidate from the expected commit SHA.
- [ ] Record test run timestamp and environment details.
- [ ] Capture known issues and mitigations for beta notes.

## Sign-off

- [ ] Engineering sign-off recorded.
- [ ] QA sign-off recorded.
- [ ] Beta release decision documented.
