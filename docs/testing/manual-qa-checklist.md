# Manual QA Checklist

## Setup

- [ ] Launch the app from Xcode on macOS 14+.
- [ ] Confirm the menu bar item shows `Echo` when idle.
- [ ] Confirm microphone and screen recording permissions are granted.
- [ ] Confirm this phase is audio-only (video capture remains out of scope for MVP).

## Recording flow

- [ ] Open the menu bar popover and verify the primary action reads `Start Recording`.
- [ ] Start recording and verify the primary action changes to `Stop Recording`.
- [ ] Verify the menu bar title changes to `Echo *` while recording.
- [ ] Stop recording and verify the menu bar title returns to `Echo`.
- [ ] Verify the primary action returns to `Start Recording`.

## Finalization flow

- [ ] Finalize a recording with a valid name like `qa-sample`.
- [ ] Verify a folder named `qa-sample` appears in the save directory (default: `~/Downloads`).
- [ ] Verify the folder contains `mixed.m4a`, `system_audio.m4a`, and `mic_audio.m4a`.
- [ ] Verify no save picker is shown yet (current MVP auto-saves by default path logic).
- [ ] Try an invalid filename like `../bad-name` and verify finalization fails with validation.

## Audio quality checks

- [ ] Record with only microphone input and verify `mic_audio.m4a` has audible speech.
- [ ] Record with only system playback and verify `system_audio.m4a` has audible app/system sound.
- [ ] Verify `mixed.m4a` contains both sources when both are active.
- [ ] Verify each generated audio file has non-zero duration (QuickTime inspector or `afinfo <path>`).

## Automated smoke harness

- [ ] Run synthetic harness: `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioRecordingHarnessTests/testSyntheticHarnessProducesReadableM4AArtifacts`
- [ ] Run live harness: create `/tmp/echo-run-live-harness`, run `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioRecordingHarnessTests/testLiveHarnessProducesNonZeroDurationWhenEnabled`, then remove the marker file.

## Regression spot checks

- [ ] Relaunch the app and confirm the menu bar controller still initializes.
- [ ] Confirm no crash occurs when opening and closing the popover repeatedly.
