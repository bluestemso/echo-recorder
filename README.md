# EchoRecorder

EchoRecorder is a macOS menu bar app prototype for capturing and finalizing recordings with a lightweight SwiftUI/AppKit UI and a test-first core architecture.

## Current status

This repository is in an early implementation phase focused on domain logic, app structure, and test coverage.

Implemented today:

- Menu bar app shell (`LSUIElement`) with a popover-based recording UI
- Recording state coordination (`idle -> preparing -> recording -> idle`)
- Input level model and UI bindings for system audio and microphone rows
- Permission wizard ordering and blocking logic
- Output finalization and filename validation
- JSON persistence and crash-recovery manifest scanning
- Unit and integration tests across core modules

Not fully implemented yet:

- Production ScreenCaptureKit capture pipeline (adapter is currently a stub)
- End-to-end audio capture/mix/write flow to media files

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
