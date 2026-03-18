# Research: Architecture

## Milestone Context
**Subsequent milestone** — Integrating live metering data and gain controls from existing backend services into the existing SwiftUI popover UI.

## Existing Architecture (Relevant Parts)
- `RecordingViewModel` (`@MainActor`, `ObservableObject`) — already has `levelRows: [LevelRowModel]` and `setGain(_ value: Float, for source:)` stub
- `MeteringService` — emits `SourceLevel` values (peak, RMS) from audio thread
- `AudioMixerService` — applies per-source gain to audio path before mixing
- `RecordingPopoverView` — SwiftUI view bound to `RecordingViewModel` via `@StateObject`/`@ObservedObject`
- `FinalizeRecordingViewModel` — handles the finalize step (naming, path override)

## Components to Add / Modify

### Live Metering Integration
```
[MeteringService (audio thread)]
    → DispatchQueue.main.async →
[RecordingViewModel (@MainActor)]
    → @Published levelRows →
[RecordingPopoverView (SwiftUI)]
    → LevelMeterView (custom Shape or animated bars)
```

**Timer-driven refresh** inside `RecordingViewModel` using `Timer.publish`:
- 50ms interval (20 fps) matches the design doc's FR-008 target
- Timer starts when recording begins, cancels when recording stops

### Gain Slider Integration
```
[RecordingPopoverView (Slider binding)]
    → RecordingViewModel.setGain(:for:) →
[AudioMixerService]
    → gain applied to PCM buffer before mix
```

Sliders bind directly to `@Published var gainRows` in `RecordingViewModel`. No threading concerns — gain updates are safe from `@MainActor`.

### Save Location Picker
```
[FinalizeRecordingView (Button: "Choose Location")]
    → NSOpenPanel (directory picker, modal)
    → FinalizeRecordingViewModel.overrideDirectory: URL?
    → passed into coordinator.stopAndFinalize(overrideDirectory:)
```

### Default Save Directory (AppSettings)
`AppSettings.defaultSaveDirectory` should be stored in `JSONStore`. Populate the finalizer's default from `AppSettings` at start of finalize flow.

## Build Order
1. Meter timer loop → `RecordingViewModel` → `levelRows` published property → `LevelMeterView`
2. Gain slider binding → `setGain` → `AudioMixerService`
3. `AppSettings.defaultSaveDirectory` persistence
4. Save location picker in finalize view → `overrideDirectory`
