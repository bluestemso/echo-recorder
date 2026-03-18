# EchoRecorder

EchoRecorder is a macOS menu bar app prototype for capturing and finalizing recordings with a lightweight SwiftUI/AppKit UI and a test-first core architecture.

## Current status

Phase 2 audio-first MVP is implemented and validated with unit, integration, and smoke harness coverage.

Implemented today:

- Menu bar app shell (`LSUIElement`) with a popover-based recording UI
- Recording state coordination (`idle -> preparing -> recording -> finalizing -> idle`)
- Input level model and UI bindings for system audio and microphone rows
- Permission request flow for microphone and screen recording
- System audio capture via ScreenCaptureKit and microphone capture via AVAudioEngine tap
- Output finalization and filename validation
- Audio writer pipeline producing `mixed.m4a`, `system_audio.m4a`, and `mic_audio.m4a`
- JSON persistence and crash-recovery manifest scanning
- Unit and integration tests across core modules
- Synthetic and live end-to-end audio smoke harness tests

Not fully implemented yet:

- Save-location picker in UI (current behavior auto-saves to `~/Downloads/Echo-<timestamp>/`)
- Optional video capture/muxing phase (audio-first MVP intentionally ships without video)

## Tech stack

- Swift
- SwiftUI + AppKit
- XCTest
- XcodeGen (`project.yml` is the source project spec)
- Target platform: macOS 14+

## Getting started

### Prerequisites

- macOS 14 or later
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Setup

1. Generate the Xcode project:

   ```bash
   xcodegen generate
   ```

2. Open the project:

   ```bash
   open EchoRecorder.xcodeproj
   ```

3. Build and run the `EchoRecorder` scheme from Xcode.

## Running tests

Run the full test suite:

```bash
xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS'
```

Run only the recording flow integration test:

```bash
xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingFlowIntegrationTests
```

Run the synthetic audio smoke harness:

```bash
xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioRecordingHarnessTests/testSyntheticHarnessProducesReadableM4AArtifacts
```

Run the live audio harness (requires granted permissions):

```bash
touch /tmp/echo-run-live-harness
xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioRecordingHarnessTests/testLiveHarnessProducesNonZeroDurationWhenEnabled
rm /tmp/echo-run-live-harness
```

## QA and release docs

- Manual QA checklist: `docs/testing/manual-qa-checklist.md`
- Beta release checklist: `docs/testing/beta-release-checklist.md`

## Project layout

- `EchoRecorder/App` - app entrypoint and app delegate bootstrap
- `EchoRecorder/UI` - menu bar, onboarding, and finalize view models/views
- `EchoRecorder/Core` - recording, permissions, capture, audio, output, persistence, and recovery services
- `EchoRecorderTests` - unit and integration tests
- `project.yml` - XcodeGen project definition

## License

MIT. See `LICENSE`.
