---
wave: 1
depends_on: []
files_modified:
  - EchoRecorder/Core/Recording/RecorderCoordinator.swift
  - EchoRecorder/Core/Audio/MeteringService.swift
  - EchoRecorder/UI/MenuBar/RecordingViewModel.swift
  - EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
  - EchoRecorderTests/UI/RecordingViewModelTests.swift
autonomous: true
requirements:
  - METER-01
  - METER-02
  - METER-03
  - METER-04
---

# Phase 1 Plan: Live Level Monitoring

## Phase Goal
User can see real-time audio level meters for system audio and mic sources in the recording popover.

## Must-Haves
1. `RecordingViewModel.levelRows` updates with real metering data at ~50ms intervals while recording
2. `RecordingPopoverView` renders color-coded bars (green/yellow/red) based on peak level
3. Meters zero out when recording is not active (idle/finalizing)
4. Metering callbacks from `RecorderCoordinator` reach `RecordingViewModel` without main-thread violations

---

## Task 1: Wire Coordinator Metering Callbacks into RecordingViewModel

<task id="1.1">
<title>Expose metering callback slots on RecorderCoordinator</title>

<read_first>
- `EchoRecorder/Core/Recording/RecorderCoordinator.swift` — current coordinator implementation
- `EchoRecorder/Core/Audio/MeteringService.swift` — SourceLevel struct and MeteringService protocol
- `EchoRecorder/Core/Audio/AudioMixerService.swift` — SourceGain, SourceLevel used in applyGain
</read_first>

<action>
Add two optional callbacks to `RecorderCoordinator` so the audio threads can push meter snapshots to any observer (the ViewModel) without strong coupling:

```swift
// In RecorderCoordinator, add alongside onSystemAudioSamples / onMicSamples:
var onMeterSnapshot: ((SourceLevel, SourceLevel) -> Void)?
```

Inside `startAudioRecording`, after capture and mic capture are set up, add a metering loop that fires on each sample buffer arrival. In the system audio sample callback:

```swift
capture.onSystemAudioSamples = { [weak self] sampleBuffer in
    self?.recordingBufferStore.appendSystem(sampleBuffer)
    // Compute and emit meter level (on the capture callback thread)
    let systemLevel = MeteringService().computeLevel(samples: sampleBuffer.samples)
    // Dispatch to main before invoking callback
    DispatchQueue.main.async {
        self?.latestSystemMeterLevel = systemLevel
        self?.emitMeterSnapshot()
    }
}
```

Add stored properties for the latest system and mic levels:
```swift
private var latestSystemMeterLevel: SourceLevel = .zero
private var latestMicMeterLevel: SourceLevel = .zero
```

In the mic sample callback:
```swift
mic.onMicSamples = { [weak self] sampleBuffer in
    self?.recordingBufferStore.appendMic(sampleBuffer)
    let micLevel = MeteringService().computeLevel(samples: sampleBuffer.samples)
    DispatchQueue.main.async {
        self?.latestMicMeterLevel = micLevel
        self?.emitMeterSnapshot()
    }
}
```

Add private `emitMeterSnapshot()` call site:
```swift
@MainActor
private func emitMeterSnapshot() {
    onMeterSnapshot?(latestSystemMeterLevel, latestMicMeterLevel)
}
```

In `stopAndFinalize` cleanup block, reset levels and clear callback:
```swift
latestSystemMeterLevel = .zero
latestMicMeterLevel = .zero
onMeterSnapshot?(SourceLevel.zero, SourceLevel.zero)
```
</action>

<acceptance_criteria>
- `EchoRecorder/Core/Recording/RecorderCoordinator.swift` contains `var onMeterSnapshot: ((SourceLevel, SourceLevel) -> Void)?`
- `EchoRecorder/Core/Recording/RecorderCoordinator.swift` contains `DispatchQueue.main.async` in at least one of the buffer callbacks
- `EchoRecorder/Core/Recording/RecorderCoordinator.swift` contains `latestSystemMeterLevel` and `latestMicMeterLevel` properties
- `EchoRecorder/Core/Recording/RecorderCoordinator.swift` contains `emitMeterSnapshot`
</acceptance_criteria>
</task>

<task id="1.2">
<title>Wire onMeterSnapshot from RecorderCoordinator into RecordingViewModel</title>

<read_first>
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` — current ViewModel implementation; observe existing init pattern with coordinator
- `EchoRecorder/UI/MenuBar/StatusItemController.swift` — how RecorderCoordinator is connected to the ViewModel
</read_first>

<action>
In `RecordingViewModel.init`, after subscribing to `recorderCoordinator?.$state`, also set the `onMeterSnapshot` callback:

```swift
recorderCoordinator?.onMeterSnapshot = { [weak self] systemLevel, micLevel in
    // Already dispatched to main by coordinator
    self?.applyMeterSnapshot(system: systemLevel, mic: micLevel)
}
```

When recording stops (state becomes `.idle`), reset level rows:

```swift
func bindRecorderState(_ state: RecorderState) {
    isRecording = state == .preparing || state == .recording || state == .finalizing
    if state == .idle {
        // Reset meters to zero when not recording
        levelRows = RecordingViewModel.InputSource.allCases.map { source in
            LevelRow(source: source, title: source.title, level: .zero)
        }
    }
}
```
</action>

<acceptance_criteria>
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` contains `recorderCoordinator?.onMeterSnapshot`
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` contains `applyMeterSnapshot(system: systemLevel, mic: micLevel)` inside the onMeterSnapshot closure
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` inside `bindRecorderState` contains a check for `state == .idle` that resets `levelRows` to `.zero`
</acceptance_criteria>
</task>

---

## Task 2: Color-Coded Level Meter View in RecordingPopoverView

<task id="2.1">
<title>Create LevelMeterView SwiftUI component</title>

<read_first>
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` — current view; note the ProgressView usage to replace
- `EchoRecorder/Core/Audio/SourceLevel.swift` — SourceLevel struct (peak: Float, rms: Float)
</read_first>

<action>
Create a new file `EchoRecorder/UI/MenuBar/LevelMeterView.swift` with a color-coded bar component:

```swift
import SwiftUI

struct LevelMeterView: View {
    let level: SourceLevel

    private var meterColor: Color {
        let peak = level.peak
        if peak >= 0.85 { return .red }
        if peak >= 0.60 { return .yellow }
        return .green
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .cornerRadius(3)
                // Filled level bar
                Rectangle()
                    .fill(meterColor)
                    .cornerRadius(3)
                    .frame(width: geometry.size.width * CGFloat(level.peak))
            }
        }
        .frame(height: 8)
        .animation(.linear(duration: 0.05), value: level.peak)
    }
}
```

Thresholds:
- `peak < 0.60` → green
- `0.60 <= peak < 0.85` → yellow
- `peak >= 0.85` → red
</action>

<acceptance_criteria>
- File `EchoRecorder/UI/MenuBar/LevelMeterView.swift` exists
- File contains `struct LevelMeterView: View`
- File contains `if peak >= 0.85 { return .red }`
- File contains `if peak >= 0.60 { return .yellow }`
- File contains `return .green`
- File contains `.animation(.linear(duration: 0.05), value: level.peak)`
</acceptance_criteria>
</task>

<task id="2.2">
<title>Replace ProgressView with LevelMeterView in RecordingPopoverView</title>

<read_first>
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` — current implementation
- `EchoRecorder/UI/MenuBar/LevelMeterView.swift` — just created in task 2.1
</read_first>

<action>
Replace the existing `ProgressView(value:total:)` calls in the `ForEach` loop with `LevelMeterView`:

Replace:
```swift
ForEach(viewModel.levelRows, id: \.source) { row in
    VStack(alignment: .leading, spacing: 4) {
        Text(row.title)
        ProgressView(value: Double(row.level.peak), total: 1)
    }
}
```

With:
```swift
ForEach(viewModel.levelRows, id: \.source) { row in
    VStack(alignment: .leading, spacing: 4) {
        Text(row.title)
            .font(.caption)
            .foregroundStyle(.secondary)
        LevelMeterView(level: row.level)
    }
}
```
</action>

<acceptance_criteria>
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` does NOT contain `ProgressView`
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` contains `LevelMeterView(level: row.level)`
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` contains `font(.caption)`
</acceptance_criteria>
</task>

---

## Task 3: Add XCTest Coverage for Meter Behavior

<task id="3.1">
<title>Write tests for meter-level color zone thresholds and idle reset</title>

<read_first>
- `EchoRecorderTests/UI/RecordingViewModelTests.swift` — existing tests; follow their patterns exactly
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` — after modifications in task 1.2
</read_first>

<action>
Add three new test methods to `EchoRecorderTests/UI/RecordingViewModelTests.swift`:

```swift
func testLevelRowsResetToZeroWhenRecordingTransitionsToIdle() {
    let viewModel = RecordingViewModel()
    viewModel.applyMeterSnapshot(
        system: SourceLevel(peak: 0.9, rms: 0.7),
        mic: SourceLevel(peak: 0.5, rms: 0.3)
    )
    // Levels are non-zero
    XCTAssertGreaterThan(viewModel.levelRows[0].level.peak, 0)

    // Transition to idle should zero out
    viewModel.bindRecorderState(.idle)
    XCTAssertEqual(viewModel.levelRows[0].level, .zero)
    XCTAssertEqual(viewModel.levelRows[1].level, .zero)
}

func testApplyMeterSnapshotUpdatesLevelRowsWithGainOf1() {
    let viewModel = RecordingViewModel()
    viewModel.setGain(1.0, for: .system)
    viewModel.setGain(1.0, for: .microphone)
    viewModel.applyMeterSnapshot(
        system: SourceLevel(peak: 0.8, rms: 0.5),
        mic: SourceLevel(peak: 0.3, rms: 0.1)
    )
    XCTAssertEqual(viewModel.levelRows[0].source, .system)
    XCTAssertEqual(viewModel.levelRows[0].level.peak, 0.8, accuracy: 0.001)
    XCTAssertEqual(viewModel.levelRows[1].source, .microphone)
    XCTAssertEqual(viewModel.levelRows[1].level.peak, 0.3, accuracy: 0.001)
}

func testApplyMeterSnapshotScalesByGain() {
    let viewModel = RecordingViewModel()
    viewModel.setGain(0.5, for: .system)
    viewModel.setGain(2.0, for: .microphone)
    viewModel.applyMeterSnapshot(
        system: SourceLevel(peak: 1.0, rms: 0.8),
        mic: SourceLevel(peak: 0.4, rms: 0.3)
    )
    XCTAssertEqual(viewModel.levelRows[0].level.peak, 0.5, accuracy: 0.001)
    XCTAssertEqual(viewModel.levelRows[1].level.peak, 0.8, accuracy: 0.001)
}
```
</action>

<acceptance_criteria>
- `EchoRecorderTests/UI/RecordingViewModelTests.swift` contains `testLevelRowsResetToZeroWhenRecordingTransitionsToIdle`
- `EchoRecorderTests/UI/RecordingViewModelTests.swift` contains `testApplyMeterSnapshotUpdatesLevelRowsWithGainOf1`
- `EchoRecorderTests/UI/RecordingViewModelTests.swift` contains `testApplyMeterSnapshotScalesByGain`
- Running `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingViewModelTests` exits with code 0
</acceptance_criteria>
</task>

---

## Task 4: Full Suite Verification

<task id="4.1">
<title>Run full test suite and commit</title>

<read_first>
- `EchoRecorder/Core/Recording/RecorderCoordinator.swift` — verify no compile errors in new metering code
</read_first>

<action>
Run the full test suite:
```bash
xcodebuild test -scheme EchoRecorder -destination 'platform=macOS'
```

Expected: All tests pass. Commit everything:
```bash
git add EchoRecorder/Core/Recording/RecorderCoordinator.swift \
        EchoRecorder/UI/MenuBar/RecordingViewModel.swift \
        EchoRecorder/UI/MenuBar/RecordingPopoverView.swift \
        EchoRecorder/UI/MenuBar/LevelMeterView.swift \
        EchoRecorderTests/UI/RecordingViewModelTests.swift
git commit -m "feat: wire live level metering into recording popover UI (Phase 1)"
```
</action>

<acceptance_criteria>
- `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS'` exits with code 0
- `LevelMeterView.swift` is tracked in git
- Git log contains commit message containing "feat: wire live level metering"
</acceptance_criteria>
</task>

---

## Verification Checklist

- [ ] METER-01: System audio level bar is visible in the popover during recording
- [ ] METER-02: Microphone level bar is visible in the popover during recording
- [ ] METER-03: Each meter bar changes color (green/yellow/red) based on signal level
- [ ] METER-04: Meter bars animate at ~50ms refresh intervals
- [ ] Meters zero out when recording stops (idle state)
- [ ] Full test suite passes
