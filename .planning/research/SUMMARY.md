# Research Summary

## Key Findings

### Stack
No new frameworks required. All needed APIs already exist in the codebase:
- **AVAudioEngine** tap → `MeteringService` already emits `SourceLevel` values
- **Combine `Timer.publish`** → drives 50ms meter refresh in `RecordingViewModel`
- **`AudioMixerService`** → already applies gain in buffer; expose via `@MainActor` setter
- **`NSOpenPanel`** (AppKit) → directory picker in finalize step (no native SwiftUI equivalent)

### Table Stakes Features
- Live RMS/peak meter bars per source (system audio, mic) — color-coded green/yellow/red
- Per-source gain slider in the active recording popover
- Save location picker at finalize step (directory override)
- Default save directory persisted in `AppSettings`

### Architecture Integration Points
| Feature | Entry Point | Pipeline |
|---------|------------|----------|
| Live meters | `MeteringService` → `DispatchQueue.main.async` → `RecordingViewModel.levelRows` | SwiftUI `LevelMeterView` |
| Gain sliders | `RecordingViewModel.setGain()` → `AudioMixerService` | SwiftUI `Slider` |
| Save location picker | `FinalizeRecordingView` → `NSOpenPanel` → `overrideDirectory` | Passed to `coordinator.stopAndFinalize()` |
| Default save dir | `AppSettings.defaultSaveDirectory` → `RecordingFinalizer` init | `JSONStore` persistence |

### Watch Out For
1. **Audio thread → main thread dispatch** — metering updates MUST be dispatched to main before touching `@Published`
2. **Timer cancellation** — the metering timer must be cancelled when recording stops (retain cycle / zombie updates risk)
3. **Gain = buffer scaling only** — do NOT reconfigure the audio graph mid-recording to apply gain; use existing in-buffer approach
4. **`NSOpenPanel.runModal()`** — call synchronously from a button action, NOT inside an `async` Task
5. **Default directory not wired** — `RecordingFinalizer` currently defaults to `temporaryDirectory`; must be updated to use `AppSettings.defaultSaveDirectory`
