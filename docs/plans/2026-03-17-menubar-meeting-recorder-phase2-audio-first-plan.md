# Menu Bar Meeting Recorder Phase 2 (Audio-First) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship an audio-first MVP that reliably records system audio + microphone from a menu bar app, with live metering, gain control, finalize naming/path selection, and recovery.

**Architecture:** Keep the existing state-machine-first foundation and swap stubs for real platform services. Use AVAudioEngine for microphone capture and ScreenCaptureKit audio stream for system audio capture only (no video track for this MVP). Write output using an audio writer pipeline that generates mixed and isolated tracks, then finalize through the existing finalize/recovery flows.

**Tech Stack:** Swift 5.10+, AppKit + SwiftUI, Combine, AVFoundation/CoreAudio, ScreenCaptureKit (audio-only), XCTest, xcodebuild, xcodegen.

---

## Implementation Status (2026-03-18)

Status: Completed and validated.

Completed tasks:
- [x] Task 1: Audio-first domain contract defaults
- [x] Task 2: Real microphone permission request path
- [x] Task 3: System audio capture callback plumbing
- [x] Task 4: Real microphone capture via AVAudioEngine tap
- [x] Task 5: Meter + gain pipeline for system and mic sources
- [x] Task 6: Audio writer pipeline for mixed and isolated m4a tracks
- [x] Task 7: Coordinator start/stop/finalize orchestration
- [x] Task 8: Recovery/integration/tests/docs updates for audio MVP

Post-implementation fixes completed after initial execution:
- Added `NSMicrophoneUsageDescription` to app Info.plist generation in `project.yml`.
- Fixed audio writer dispatch bug where protocol extension fallback dropped real recording data.
- Added PCM sample extraction support for interleaved and integer formats.
- Added deterministic and live smoke harness tests for audio output verification.

Current verification baseline:
- Full suite: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS'`
- Synthetic harness: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioRecordingHarnessTests/testSyntheticHarnessProducesReadableM4AArtifacts`
- Live harness (opt-in): create `/tmp/echo-run-live-harness`, then run `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioRecordingHarnessTests/testLiveHarnessProducesNonZeroDurationWhenEnabled`

Execution notes:
- Use `@superpowers:test-driven-development` during every task.
- Keep changes small and commit after each task.
- Run targeted tests first, then run full suite at the end of each integration-heavy task.

### Task 1: Audio-First Domain Contract

**Files:**
- Modify: `EchoRecorder/Core/Models/Profile.swift`
- Modify: `EchoRecorder/Core/Models/AppSettings.swift`
- Modify: `EchoRecorder/Core/Models/RecordingManifest.swift`
- Create: `EchoRecorderTests/Models/AudioFirstModelTests.swift`

**Step 1: Write the failing test**

```swift
func testProfileDefaultsToAudioOnlyMVP() {
    let profile = Profile(id: "default", name: "Default")
    XCTAssertTrue(profile.includeSystemAudio)
    XCTAssertNotNil(profile.micDeviceID)
    XCTAssertEqual(profile.captureMode, .audioOnly)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioFirstModelTests/testProfileDefaultsToAudioOnlyMVP`
Expected: FAIL with missing `captureMode` and audio-first defaults.

**Step 3: Write minimal implementation**

```swift
enum CaptureMode: String, Codable {
    case audioOnly
    case audioAndVideo
}

struct Profile: Codable, Equatable {
    let id: String
    let name: String
    let includeSystemAudio: Bool
    let micDeviceID: String?
    let captureMode: CaptureMode
}
```

Set defaults to audio-first.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Models EchoRecorderTests/Models/AudioFirstModelTests.swift
git commit -m "feat: set audio-first model defaults for MVP"
```

### Task 2: Real Microphone Permission + Request Path

**Files:**
- Modify: `EchoRecorder/Core/Permissions/PermissionType.swift`
- Modify: `EchoRecorder/Core/Permissions/PermissionManager.swift`
- Modify: `EchoRecorder/UI/Onboarding/PermissionWizardViewModel.swift`
- Modify: `EchoRecorderTests/Permissions/PermissionWizardViewModelTests.swift`
- Create: `EchoRecorderTests/Permissions/PermissionManagerAudioTests.swift`

**Step 1: Write the failing test**

```swift
func testRequestMicrophoneReturnsAuthorizedWhenProviderGrants() async {
    let manager = PermissionManager(
        statusProvider: { _ in .notDetermined },
        requestProvider: { permission in permission == .microphone ? .authorized : .denied }
    )
    let status = await manager.request(.microphone)
    XCTAssertEqual(status, .authorized)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/PermissionManagerAudioTests`
Expected: FAIL with missing `request` API.

**Step 3: Write minimal implementation**

```swift
protocol PermissionManaging {
    func status(for permission: PermissionType) -> PermissionStatus
    func request(_ permission: PermissionType) async -> PermissionStatus
}
```

Back with injectable providers for tests and production AVFoundation authorization requests.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Permissions EchoRecorder/UI/Onboarding EchoRecorderTests/Permissions
git commit -m "feat: implement microphone permission request flow"
```

### Task 3: System Audio Capture Service (Audio-Only)

**Files:**
- Modify: `EchoRecorder/Core/Capture/CaptureSourceDescriptor.swift`
- Modify: `EchoRecorder/Core/Capture/ScreenCaptureKitAdapter.swift`
- Modify: `EchoRecorder/Core/Capture/CaptureService.swift`
- Create: `EchoRecorder/Core/Capture/SystemAudioSampleBuffer.swift`
- Modify: `EchoRecorderTests/Capture/CaptureServiceContractTests.swift`
- Create: `EchoRecorderTests/Capture/SystemAudioCaptureTests.swift`

**Step 1: Write the failing test**

```swift
func testStartSystemAudioCapturePublishesSampleCallback() async throws {
    let adapter = FakeSystemAudioAdapter()
    let service = CaptureService(adapter: adapter)
    var callbackCount = 0
    service.onSystemAudioSamples = { _ in callbackCount += 1 }
    try await service.startCapture(source: .systemAudio)
    adapter.emitFakeAudioFrame()
    XCTAssertEqual(callbackCount, 1)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/SystemAudioCaptureTests`
Expected: FAIL with missing callback path.

**Step 3: Write minimal implementation**

```swift
struct SystemAudioSampleBuffer {
    let samples: [Float]
    let sampleRate: Double
    let channelCount: Int
}
```

Expose `onSystemAudioSamples` on capture service and wire adapter callback.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Capture EchoRecorderTests/Capture
git commit -m "feat: add audio-only system capture callback flow"
```

### Task 4: Real Mic Capture via AVAudioEngine Tap

**Files:**
- Modify: `EchoRecorder/Core/Audio/MicCaptureService.swift`
- Create: `EchoRecorder/Core/Audio/MicSampleBuffer.swift`
- Modify: `EchoRecorderTests/Audio/MicCaptureServiceTests.swift`
- Create: `EchoRecorderTests/Audio/MicCaptureTapTests.swift`

**Step 1: Write the failing test**

```swift
func testStartCaptureInstallsTapAndEmitsMicSamples() throws {
    let engine = FakeAudioEngine()
    let service = MicCaptureService(engine: engine)
    var sampleEvents = 0
    service.onMicSamples = { _ in sampleEvents += 1 }
    try service.startCapture()
    engine.emitFakeInputBuffer()
    XCTAssertEqual(sampleEvents, 1)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/MicCaptureTapTests`
Expected: FAIL with missing tap callback wiring.

**Step 3: Write minimal implementation**

```swift
struct MicSampleBuffer {
    let samples: [Float]
    let sampleRate: Double
    let channelCount: Int
}
```

Add `onMicSamples` callback and wire AVAudioEngine input tap in production path.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Audio EchoRecorderTests/Audio
git commit -m "feat: wire AVAudioEngine mic tap into sample callback stream"
```

### Task 5: Meter + Gain Pipeline for System and Mic Sources

**Files:**
- Modify: `EchoRecorder/Core/Audio/MeteringService.swift`
- Modify: `EchoRecorder/Core/Audio/AudioMixerService.swift`
- Modify: `EchoRecorder/UI/MenuBar/RecordingViewModel.swift`
- Modify: `EchoRecorderTests/UI/RecordingViewModelTests.swift`
- Create: `EchoRecorderTests/Audio/AudioGainPipelineTests.swift`

**Step 1: Write the failing test**

```swift
func testApplyGainChangesMeteredPeakForMicSource() {
    let vm = RecordingViewModel()
    vm.setGain(0.5, for: .microphone)
    vm.applyMeterSnapshot(system: .init(peak: 1.0, rms: 0.5), mic: .init(peak: 0.8, rms: 0.4))
    XCTAssertEqual(vm.levelRows.last?.level.peak, 0.4, accuracy: 0.001)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioGainPipelineTests`
Expected: FAIL with missing gain application path.

**Step 3: Write minimal implementation**

```swift
struct SourceGain {
    var system: Float
    var microphone: Float
}
```

Apply gain before presenting level rows and keep deterministic order.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Audio EchoRecorder/UI/MenuBar EchoRecorderTests/Audio EchoRecorderTests/UI
git commit -m "feat: apply per-source gain in live metering pipeline"
```

### Task 6: Audio Writer Pipeline (Mixed + Isolated m4a)

**Files:**
- Modify: `EchoRecorder/Core/Output/FileWriterService.swift`
- Modify: `EchoRecorder/Core/Output/RecordingFinalizer.swift`
- Create: `EchoRecorder/Core/Output/AudioWriterPipeline.swift`
- Modify: `EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift`
- Modify: `EchoRecorderTests/Output/RecordingFinalizerTests.swift`
- Create: `EchoRecorderTests/Output/AudioWriterPipelineTests.swift`

**Step 1: Write the failing test**

```swift
func testFinalizeReturnsMixedAndIsolatedAudioArtifactPaths() throws {
    let pipeline = FakeAudioWriterPipeline()
    let finalizer = RecordingFinalizer(fileWriter: FileWriterService(pipeline: pipeline), defaultDirectory: temp)
    let output = try finalizer.finalize(fileName: "standup", overrideDirectory: nil)
    XCTAssertEqual(output.mixed.lastPathComponent, "mixed.m4a")
    XCTAssertEqual(output.system.lastPathComponent, "system_audio.m4a")
    XCTAssertEqual(output.mic.lastPathComponent, "mic_audio.m4a")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioWriterPipelineTests`
Expected: FAIL with missing output model and pipeline.

**Step 3: Write minimal implementation**

```swift
struct FinalizedAudioOutput {
    let folder: URL
    let mixed: URL
    let system: URL
    let mic: URL
}
```

Keep production writer behind protocol for testability.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Output EchoRecorder/UI/Finalize EchoRecorderTests/Output
git commit -m "feat: implement audio writer outputs for mixed and isolated tracks"
```

### Task 7: Coordinator Start/Stop/Finalize Orchestration (Audio-First)

**Files:**
- Modify: `EchoRecorder/Core/Recording/RecorderState.swift`
- Modify: `EchoRecorder/Core/Recording/RecorderCoordinator.swift`
- Modify: `EchoRecorder/UI/MenuBar/StatusItemController.swift`
- Modify: `EchoRecorder/UI/MenuBar/RecordingViewModel.swift`
- Modify: `EchoRecorderTests/Recording/RecorderCoordinatorTests.swift`
- Create: `EchoRecorderTests/Recording/AudioFirstRecorderOrchestrationTests.swift`

**Step 1: Write the failing test**

```swift
func testStopFinalizesAudioAndReturnsToIdle() async throws {
    let sut = RecorderCoordinator(capture: fakeCapture, mic: fakeMic, finalizer: fakeFinalizer)
    try await sut.startAudioRecording(profile: .audioFixture)
    let output = try await sut.stopAndFinalize(recordingName: "demo", overrideDirectory: nil)
    XCTAssertEqual(sut.state, .idle)
    XCTAssertEqual(output.mixed.lastPathComponent, "mixed.m4a")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AudioFirstRecorderOrchestrationTests`
Expected: FAIL with missing async orchestration methods.

**Step 3: Write minimal implementation**

```swift
@MainActor
func startAudioRecording(profile: Profile) async throws

@MainActor
func stopAndFinalize(recordingName: String, overrideDirectory: URL?) async throws -> FinalizedAudioOutput
```

Wire state transitions and service calls only for audio path.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Recording EchoRecorder/UI/MenuBar EchoRecorderTests/Recording
git commit -m "feat: orchestrate audio-first recording lifecycle in coordinator"
```

### Task 8: Recovery + Integration + QA Docs for Audio MVP

**Files:**
- Modify: `EchoRecorder/Core/Recovery/RecoveryService.swift`
- Modify: `EchoRecorderTests/Recovery/RecoveryServiceTests.swift`
- Modify: `EchoRecorderTests/Integration/RecordingFlowIntegrationTests.swift`
- Modify: `docs/testing/manual-qa-checklist.md`
- Modify: `docs/testing/beta-release-checklist.md`

**Step 1: Write the failing test**

```swift
func testAudioIntegrationFlowIdleToRecordingToFinalizeToIdle() async throws {
    let harness = AudioIntegrationHarness.makeWithFakes()
    try await harness.start()
    let output = try await harness.stopAndFinalize(name: "audio-mvp")
    XCTAssertEqual(harness.state, .idle)
    XCTAssertEqual(output.mixed.pathExtension, "m4a")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingFlowIntegrationTests`
Expected: FAIL with outdated integration assertions.

**Step 3: Write minimal implementation**

```swift
// Update integration harness to assert audio artifact paths and recovery manifest behavior.
```

Update QA docs for audio-only verification steps and keep video marked as out-of-scope for MVP.

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Run full suite and commit**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS'`
Expected: PASS all tests.

```bash
git add EchoRecorder/Core/Recovery EchoRecorderTests/Recovery EchoRecorderTests/Integration docs/testing/manual-qa-checklist.md docs/testing/beta-release-checklist.md
git commit -m "test: align integration and qa checklists for audio-first MVP"
```

## Post-MVP Optional Add-On (Video)

When audio MVP is stable, add a separate Phase 3 plan for optional window video capture + muxing. Do not block MVP release on this.
