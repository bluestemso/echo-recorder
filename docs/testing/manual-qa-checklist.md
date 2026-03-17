# Manual QA Checklist

## Setup

- [ ] Launch the app from Xcode on macOS 14+.
- [ ] Confirm the menu bar item shows `Echo` when idle.
- [ ] Confirm microphone and screen recording permissions are granted.

## Recording flow

- [ ] Open the menu bar popover and verify the primary action reads `Start Recording`.
- [ ] Start recording and verify the primary action changes to `Stop Recording`.
- [ ] Verify the menu bar title changes to `Echo *` while recording.
- [ ] Stop recording and verify the menu bar title returns to `Echo`.
- [ ] Verify the primary action returns to `Start Recording`.

## Finalization flow

- [ ] Finalize a recording with a valid filename like `qa-sample.m4a`.
- [ ] Verify the recording file appears in the configured save directory with the expected filename.
- [ ] Try an invalid filename like `../bad-name` and verify finalization fails with validation.

## Regression spot checks

- [ ] Relaunch the app and confirm the menu bar controller still initializes.
- [ ] Confirm no crash occurs when opening and closing the popover repeatedly.
