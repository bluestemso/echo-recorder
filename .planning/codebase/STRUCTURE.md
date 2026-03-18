# Directory Structure Map

## Root Organization
- `EchoRecorder/`: Main application source code directory.
  - `App/`: Entry points and app lifecycle (`EchoRecorderApp.swift`, `AppDelegate.swift`).
  - `Core/`: Business logic, services, and managers.
  - `UI/`: Presentation layer, SwiftUI views, ViewModels, and AppKit integrations.
- `EchoRecorderTests/`: Unit tests directory (XCTest).
- `project.yml`: XcodeGen configuration file.

## Core (`EchoRecorder/Core/`)
- `Audio/`: Audio processing/mixing pipelines (`AudioMixerService`, `PCMBufferSampleExtractor`).
- `Capture/`: Source capture logic, primarily SCK adapter (`ScreenCaptureKitAdapter`).
- `Models/`: Data transfer objects and central entities.
- `Output/`: File writing and processing logic post-recording.
- `Permissions/`: macOS TCC permission flows.
- `Persistence/`: Local user storage (`JSONStore`).
- `Recording/`: The primary `RecorderCoordinator` orchestrating the recording lifecycle.
- `Recovery/`: Logic designed to handle crashes or incomplete recordings.

## UI (`EchoRecorder/UI/`)
- `Finalize/`: Screens shown after a successful recording.
- `MenuBar/`: AppKit status item rendering and related `RecordingPopoverView`/`RecordingViewModel`.
- `Onboarding/`: Screens covering initial setup, like requesting microphone/SCK permissions.

## Naming Conventions
- Component namespaces via directories rather than long prefixes.
- `*Service` for single-responsibility logic classes (e.g., `MicCaptureService`, `CaptureService`).
- `*Coordinator` for multi-service orchestrators (e.g., `RecorderCoordinator`).
- `*ViewModel` for SwiftUI business logic bridges (e.g., `RecordingViewModel`).
