---
wave: 1
depends_on: []
files_modified:
  - EchoRecorder/UI/MenuBar/RecordingViewModel.swift
  - EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
  - EchoRecorderTests/UI/RecordingViewModelTests.swift
autonomous: true
---

# Phase 2, Plan 01: Gain Slider UI

## Goal

Add per-source gain sliders to the recording popover and expose `gainValues` from the view model so SwiftUI can bind to it.

---

## Requirements

- GAIN-01: User can adjust gain of system audio source via slider in recording popover
- GAIN-02: User can adjust gain of microphone source via slider in recording popover
- GAIN-03: Changing a gain slider visibly affects the corresponding live meter in real-time

---

## Tasks

### Task 1: Expose `gainValues` from RecordingViewModel

<read_first>
- EchoRecorder/UI/MenuBar/RecordingViewModel.swift
- EchoRecorder/Core/Audio/AudioMixerService.swift
</read_first>

<action>
In `RecordingViewModel.swift`:

1. Add a new `@Published` property after `latestErrorDescription`:
```swift
@Published private(set) var gainValues: [InputSource: Float] = [
    .system: 1.0,
    .microphone: 1.0
]
```

2. Update `setGain(_:for:)` to also write to `gainValues`:
```swift
func setGain(_ value: Float, for source: InputSource) {
    switch source {
    case .system:
        sourceGain.system = value
    case .microphone:
        sourceGain.microphone = value
    }
    gainValues[source] = value
}
```
</action>

<acceptance_criteria>
- `RecordingViewModel.swift` contains `@Published private(set) var gainValues: [InputSource: Float]`
- `gainValues` is initialized with `[.system: 1.0, .microphone: 1.0]`
- `setGain(_:for:)` contains `gainValues[source] = value`
</acceptance_criteria>

---

### Task 2: Add Gain Slider to RecordingPopoverView

<read_first>
- EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
- EchoRecorder/UI/MenuBar/LevelMeterView.swift
- EchoRecorder/UI/MenuBar/RecordingViewModel.swift
</read_first>

<action>
Replace the `ForEach` body in `RecordingPopoverView.swift` to add a gain slider below each meter:

```swift
ForEach(viewModel.levelRows, id: \.source) { row in
    VStack(alignment: .leading, spacing: 4) {
        Text(row.title)
            .font(.caption)
            .foregroundStyle(.secondary)
        LevelMeterView(level: row.level)
        HStack(spacing: 6) {
            Text("Gain")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { viewModel.gainValues[row.source] ?? 1.0 },
                    set: { viewModel.setGain($0, for: row.source) }
                ),
                in: 0.0...2.0
            )
        }
    }
}
```
</action>

<acceptance_criteria>
- `RecordingPopoverView.swift` contains `Slider(`
- `RecordingPopoverView.swift` contains `viewModel.gainValues[row.source]`
- `RecordingPopoverView.swift` contains `viewModel.setGain($0, for: row.source)`
- `RecordingPopoverView.swift` contains `in: 0.0...2.0`
</acceptance_criteria>

---

### Task 3: Add Tests for gainValues Published State

<read_first>
- EchoRecorderTests/UI/RecordingViewModelTests.swift
- EchoRecorder/UI/MenuBar/RecordingViewModel.swift
</read_first>

<action>
Append two new tests to `RecordingViewModelTests.swift` inside the class body:

```swift
func testGainValuesInitializedToUnity() {
    let viewModel = RecordingViewModel()
    XCTAssertEqual(viewModel.gainValues[.system], 1.0)
    XCTAssertEqual(viewModel.gainValues[.microphone], 1.0)
}

func testSetGainUpdatesGainValuesPublished() {
    let viewModel = RecordingViewModel()
    viewModel.setGain(0.75, for: .system)
    viewModel.setGain(1.5, for: .microphone)
    XCTAssertEqual(viewModel.gainValues[.system], 0.75)
    XCTAssertEqual(viewModel.gainValues[.microphone], 1.5)
}
```
</action>

<acceptance_criteria>
- `RecordingViewModelTests.swift` contains `testGainValuesInitializedToUnity`
- `RecordingViewModelTests.swift` contains `testSetGainUpdatesGainValuesPublished`
- `RecordingViewModelTests.swift` contains `XCTAssertEqual(viewModel.gainValues[.system], 0.75)`
</acceptance_criteria>

---

## Verification

```bash
xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' \
  -only-testing:EchoRecorderTests/RecordingViewModelTests
```

Expected: all RecordingViewModelTests pass (was 7, now 9).

```bash
xcodebuild test -scheme EchoRecorder -destination 'platform=macOS'
```

Expected: all tests pass, 0 failures.

---

## Must-Haves (Goal-Backward Verification)

Phase goal: *"User can adjust the gain (volume level) of each audio source via sliders while recording, and the live meters reflect the change."*

- [ ] Slider is visible in the popover for system audio row
- [ ] Slider is visible in the popover for microphone row
- [ ] Moving slider calls `setGain()` which updates `sourceGain` (already wired to `applyMeterSnapshot`)
- [ ] The meter level changes within the next meter callback cycle (~50ms)
- [ ] All existing tests still pass (no regressions)
