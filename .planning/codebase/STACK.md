# Tech Stack Map

## Overview
EchoRecorder is a native macOS menu bar application designed to capture system audio and microphone input using standard Apple frameworks.

## Languages & Platforms
- **Language**: Swift
- **Platform**: macOS 14.0+
- **Architecture**: AppKit (AppDelegate) wrapped in SwiftUI (`@main` struct using `NSApplicationDelegateAdaptor`)

## Core Frameworks
- **UI**: `SwiftUI` for views (`RecordingPopoverView.swift`), `AppKit` for menu bar integration (`NSStatusItem`).
- **Audio Capture**: `AVFoundation` (microphone capture via `AVCaptureSession` / `AVAudioEngine` or `ScreenCaptureKit` for system audio).
- **Screen Capture**: `ScreenCaptureKit` (`ScreenCaptureKitAdapter.swift`).

## Dependencies
- **Package Manager**: None (native). Uses `XcodeGen` (`project.yml`) to generate the `.xcodeproj`.
- **External Libraries**: None identified in `project.yml`. Completely dependency-free.

## Build System
- **Tool**: XcodeGen
- **Configuration**: Defined in `project.yml`, generating `EchoRecorder.xcodeproj`.
