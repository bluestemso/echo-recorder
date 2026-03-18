# Testing Map

## Framework & Structure
- **Framework**: `XCTest`. Built as a standard macOS unit test bundle (`EchoRecorderTests`).
- **Organization**: Test directories mirror the main App/Core/UI directories exactly (e.g., `Audio`, `Capture`, `Integration`, `Models`, `Output`, `Permissions`, `Persistence`, `Recording`, `Recovery`, `UI`), with an additional `Smoke` suite.
- **Execution**: Configured in `project.yml` under `EchoRecorderTests` target. Can be run via Xcode or `xcodebuild test`.

## Practices
- High use of protocol-based abstractions in the main app (e.g., `CaptureServicing`) allows for easy mock injection during tests.
- Broad test coverage is expected across unit levels, integration levels, and app launch scenarios (`AppLaunchTests.swift`).
