# Research: Stack

## Milestone Context
**Subsequent milestone** — Adding live metering UI, per-source gain controls, and save location picker to an existing macOS audio recording app.

## Existing Stack (From Codebase)
- **Swift 5.10+** with strict concurrency (`@MainActor`, `Sendable`)
- **SwiftUI + AppKit** — `NSStatusItem` + `NSPopover` housing SwiftUI views
- **AVFoundation / AVAudioEngine** — mic tap via `installTap(onBus:...)`
- **ScreenCaptureKit** — system audio capture (audio-only path)
- **Combine** — `@Published` / `ObservableObject` binding from `RecordingViewModel`
- **XCTest** — test-first culture with unit, integration, smoke harness levels

## What's Needed to Surface Live Metering in UI

### Metering Data Path
`MeteringService` already emits `SourceLevel` snapshots. The gap is wiring these into a timer-driven view refresh loop:

```swift
// Recommended pattern: Timer.publish drives UI refresh from @Published properties
Timer.publish(every: 0.05, on: .main, in: .common)
    .autoconnect()
    .sink { [weak self] _ in
        self?.applyMeterSnapshot(...)
    }
```

**Confidence: High** — `RecordingViewModel.levelRows` already models this; just needs timer wiring + SwiftUI binding.

### Audio Tap → Main Thread Handoff
The `tapBlock` runs on a real-time audio thread. Current `MeteringService` must dispatch to main before updating any `@Published` property:

```swift
// Inside tap block:
DispatchQueue.main.async {
    self.systemLevel = calculatedLevel
}
// OR use AsyncStream + MainActor consumption
```

**Confidence: High** — Critical constraint; violation causes crashes.

## Gain Control
Per-source gain is applied via `AudioMixerService`. Exposing this as a SwiftUI `Slider` binding requires an `@MainActor` setter that adjusts the mixer gain value, which is safe to set from the main thread.

## Save Location Picker
No native SwiftUI file picker exists for macOS save dialogs (as of 2025). Use `NSSavePanel`/`NSOpenPanel` directly:

```swift
func pickDirectory() -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    return panel.runModal() == .OK ? panel.url : nil
}
```

**Confidence: High** — Standard macOS pattern; well-established community approach.

## Recommended Approach
Lean fully on the existing architecture. No new frameworks needed. The work is connecting what's already built in the backend (metering, gain, finalizer) to the SwiftUI UI layer.
