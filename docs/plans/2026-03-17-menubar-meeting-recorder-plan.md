# Menu Bar Meeting Recorder Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native Swift macOS menu bar app that records a selected meeting window with system + mic audio, provides live meters and gain controls, and finalizes recordings with rename/save-location options.

**Architecture:** Use a menu bar shell (`NSStatusItem`/popover) backed by a strict `RecorderCoordinator` state machine. Isolate capture, metering, and file writing behind protocols so orchestration is testable with fakes. Persist profiles/settings/manifests in `Application Support` and recover interrupted sessions on launch.

**Tech Stack:** Swift 5.10+, AppKit + SwiftUI, ScreenCaptureKit, AVFoundation/Core Audio, XCTest, xcodebuild.

---

Execution notes:
- Use `@superpowers:test-driven-development` during each task.
- Keep commits small and task-scoped.
- Run targeted tests before broad suite.

### Task 1: Project Skeleton and Baseline Test Harness

**Files:**
- Create: `EchoRecorder.xcodeproj` (app + test targets)
- Create: `EchoRecorder/App/EchoRecorderApp.swift`
- Create: `EchoRecorder/App/AppDelegate.swift`
- Create: `EchoRecorderTests/AppLaunchTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import EchoRecorder

final class AppLaunchTests: XCTestCase {
    func testAppDelegateCreatesStatusItemController() {
        let appDelegate = AppDelegate()
        appDelegate.applicationDidFinishLaunching(.init(name: Notification.Name("test")))
        XCTAssertNotNil(appDelegate.statusItemController)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/AppLaunchTests/testAppDelegateCreatesStatusItemController`
Expected: FAIL with missing `statusItemController`.

**Step 3: Write minimal implementation**

```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController()
    }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder.xcodeproj EchoRecorder/App/EchoRecorderApp.swift EchoRecorder/App/AppDelegate.swift EchoRecorderTests/AppLaunchTests.swift
git commit -m "feat: bootstrap menu bar app target with baseline tests"
```

### Task 2: Profile/Settings/Manifest Persistence

**Files:**
- Create: `EchoRecorder/Core/Models/Profile.swift`
- Create: `EchoRecorder/Core/Models/AppSettings.swift`
- Create: `EchoRecorder/Core/Models/RecordingManifest.swift`
- Create: `EchoRecorder/Core/Persistence/JSONStore.swift`
- Create: `EchoRecorderTests/Persistence/JSONStoreTests.swift`

**Step 1: Write the failing test**

```swift
func testJSONStoreRoundTripsProfile() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = JSONStore(baseURL: url)
    let profile = Profile(id: UUID(), name: "Default", includeSystemAudio: true, micDeviceID: "built-in")

    try store.save(profile, as: "profile.json")
    let loaded: Profile = try store.load("profile.json")

    XCTAssertEqual(loaded.name, "Default")
    XCTAssertTrue(loaded.includeSystemAudio)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/JSONStoreTests/testJSONStoreRoundTripsProfile`
Expected: FAIL with missing model/store types.

**Step 3: Write minimal implementation**

```swift
struct Profile: Codable, Equatable { ... }
struct AppSettings: Codable, Equatable { ... }
struct RecordingManifest: Codable, Equatable { ... }

final class JSONStore {
    func save<T: Encodable>(_ value: T, as filename: String) throws { ... }
    func load<T: Decodable>(_ filename: String) throws -> T { ... }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Models EchoRecorder/Core/Persistence EchoRecorderTests/Persistence/JSONStoreTests.swift
git commit -m "feat: add codable models and JSON persistence layer"
```

### Task 3: Recorder State Machine and Transition Safety

**Files:**
- Create: `EchoRecorder/Core/Recording/RecorderState.swift`
- Create: `EchoRecorder/Core/Recording/RecorderCoordinator.swift`
- Create: `EchoRecorderTests/Recording/RecorderCoordinatorTests.swift`

**Step 1: Write the failing test**

```swift
func testStartFromIdleTransitionsToPreparing() {
    let coordinator = RecorderCoordinator(...fakes...)
    coordinator.startRecording()
    XCTAssertEqual(coordinator.state, .preparing)
}

func testStartWhileRecordingIsIgnored() {
    let coordinator = RecorderCoordinator(...fakes...)
    coordinator.forceState(.recording)
    coordinator.startRecording()
    XCTAssertEqual(coordinator.startInvocationCount, 0)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecorderCoordinatorTests`
Expected: FAIL with missing coordinator/state.

**Step 3: Write minimal implementation**

```swift
enum RecorderState { case idle, preparing, recording, stopping, finalizing }

final class RecorderCoordinator {
    @Published private(set) var state: RecorderState = .idle
    func startRecording() { guard state == .idle else { return }; state = .preparing }
    func markRecordingStarted() { state = .recording }
    func stopRecording() { guard state == .recording else { return }; state = .stopping }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Recording EchoRecorderTests/Recording/RecorderCoordinatorTests.swift
git commit -m "feat: add recording state machine with guarded transitions"
```

### Task 4: Guided Permission Wizard Logic

**Files:**
- Create: `EchoRecorder/Core/Permissions/PermissionType.swift`
- Create: `EchoRecorder/Core/Permissions/PermissionManager.swift`
- Create: `EchoRecorder/UI/Onboarding/PermissionWizardViewModel.swift`
- Create: `EchoRecorderTests/Permissions/PermissionWizardViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testWizardBlocksContinueWhenScreenPermissionDenied() {
    let manager = FakePermissionManager(screen: .denied, mic: .authorized, camera: .authorized)
    let vm = PermissionWizardViewModel(permissionManager: manager)
    vm.refresh()
    XCTAssertFalse(vm.canContinue)
    XCTAssertEqual(vm.blockingPermission, .screenRecording)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/PermissionWizardViewModelTests`
Expected: FAIL with missing view model/permission types.

**Step 3: Write minimal implementation**

```swift
enum PermissionType { case screenRecording, microphone, camera }
enum PermissionStatus { case notDetermined, denied, authorized }

final class PermissionWizardViewModel: ObservableObject {
    @Published var canContinue = false
    @Published var blockingPermission: PermissionType?
    func refresh() { ... }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Permissions EchoRecorder/UI/Onboarding EchoRecorderTests/Permissions
git commit -m "feat: implement guided permission wizard decision logic"
```

### Task 5: Window/System Capture Service Abstraction

**Files:**
- Create: `EchoRecorder/Core/Capture/CaptureSourceDescriptor.swift`
- Create: `EchoRecorder/Core/Capture/CaptureService.swift`
- Create: `EchoRecorder/Core/Capture/ScreenCaptureKitAdapter.swift`
- Create: `EchoRecorderTests/Capture/CaptureServiceContractTests.swift`

**Step 1: Write the failing test**

```swift
func testStartCapturePublishesRunningState() async throws {
    let service = FakeCaptureService()
    try await service.startCapture(source: .window(id: "w1"), includeSystemAudio: true)
    XCTAssertTrue(service.isRunning)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/CaptureServiceContractTests`
Expected: FAIL with missing capture protocol/types.

**Step 3: Write minimal implementation**

```swift
protocol CaptureService {
    var isRunning: Bool { get }
    func availableWindows() async throws -> [CaptureSourceDescriptor]
    func startCapture(source: CaptureSourceDescriptor, includeSystemAudio: Bool) async throws
    func stopCapture() async
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Capture EchoRecorderTests/Capture
git commit -m "feat: add capture abstraction and screen capture adapter scaffold"
```

### Task 6: Mic Capture, Mixer, and Metering

**Files:**
- Create: `EchoRecorder/Core/Audio/MicCaptureService.swift`
- Create: `EchoRecorder/Core/Audio/AudioMixerService.swift`
- Create: `EchoRecorder/Core/Audio/MeteringService.swift`
- Create: `EchoRecorder/Core/Audio/SourceLevel.swift`
- Create: `EchoRecorderTests/Audio/MeteringServiceTests.swift`

**Step 1: Write the failing test**

```swift
func testMeteringProducesExpectedPeakAndRMS() {
    let samples: [Float] = [0, 0.5, -0.5, 1.0, -1.0]
    let meter = MeteringService()
    let level = meter.level(for: samples)
    XCTAssertEqual(level.peak, 1.0, accuracy: 0.001)
    XCTAssertGreaterThan(level.rms, 0.0)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/MeteringServiceTests`
Expected: FAIL with missing metering implementation.

**Step 3: Write minimal implementation**

```swift
struct SourceLevel { let rms: Float; let peak: Float }

final class MeteringService {
    func level(for samples: [Float]) -> SourceLevel { ... }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Audio EchoRecorderTests/Audio
git commit -m "feat: add audio metering and mixer scaffolding"
```

### Task 7: Menu Bar Popover with Live Controls

**Files:**
- Create: `EchoRecorder/UI/MenuBar/StatusItemController.swift`
- Create: `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift`
- Create: `EchoRecorder/UI/MenuBar/RecordingViewModel.swift`
- Create: `EchoRecorderTests/UI/RecordingViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testViewModelMapsSourceLevelsToDisplayRows() {
    let vm = RecordingViewModel(coordinator: FakeCoordinator())
    vm.update(levels: [.system: .init(rms: 0.2, peak: 0.4)])
    XCTAssertEqual(vm.rows.count, 1)
    XCTAssertEqual(vm.rows.first?.title, "System Audio")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingViewModelTests`
Expected: FAIL with missing view model/row mapping.

**Step 3: Write minimal implementation**

```swift
final class RecordingViewModel: ObservableObject {
    @Published var rows: [SourceRow] = []
    func update(levels: [AudioSource: SourceLevel]) { ... }
    func setGain(_ value: Float, for source: AudioSource) { ... }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/UI/MenuBar EchoRecorderTests/UI
git commit -m "feat: add menu bar popover view model and live control bindings"
```

### Task 8: File Finalization and Save Options

**Files:**
- Create: `EchoRecorder/Core/Output/FileWriterService.swift`
- Create: `EchoRecorder/Core/Output/RecordingFinalizer.swift`
- Create: `EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift`
- Create: `EchoRecorderTests/Output/RecordingFinalizerTests.swift`

**Step 1: Write the failing test**

```swift
func testFinalizerUsesDefaultDirectoryWhenOverrideNil() throws {
    let finalizer = RecordingFinalizer(writer: FakeWriter(), settings: .init(defaultSaveDirectory: "/tmp/rec"))
    let output = try finalizer.finalize(name: "Daily Standup", overrideDirectory: nil)
    XCTAssertTrue(output.masterPath.hasPrefix("/tmp/rec"))
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingFinalizerTests`
Expected: FAIL with missing finalizer/writer.

**Step 3: Write minimal implementation**

```swift
final class RecordingFinalizer {
    func finalize(name: String, overrideDirectory: String?) throws -> FinalizedOutput {
        ...
    }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Output EchoRecorder/UI/Finalize EchoRecorderTests/Output
git commit -m "feat: implement recording finalization with directory override support"
```

### Task 9: Recovery Flow for Interrupted Sessions

**Files:**
- Create: `EchoRecorder/Core/Recovery/RecoveryService.swift`
- Modify: `EchoRecorder/Core/Models/RecordingManifest.swift`
- Modify: `EchoRecorder/App/AppDelegate.swift`
- Create: `EchoRecorderTests/Recovery/RecoveryServiceTests.swift`

**Step 1: Write the failing test**

```swift
func testRecoveryServiceFindsUnfinalizedManifests() throws {
    let service = RecoveryService(store: tempStoreWithUnfinalizedManifest())
    let sessions = try service.pendingRecoverySessions()
    XCTAssertEqual(sessions.count, 1)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecoveryServiceTests`
Expected: FAIL with missing recovery service.

**Step 3: Write minimal implementation**

```swift
final class RecoveryService {
    func pendingRecoverySessions() throws -> [RecordingManifest] { ... }
    func recover(_ manifest: RecordingManifest) throws { ... }
}
```

**Step 4: Run test to verify it passes**

Run: same command as Step 2
Expected: PASS

**Step 5: Commit**

```bash
git add EchoRecorder/Core/Recovery EchoRecorder/Core/Models/RecordingManifest.swift EchoRecorder/App/AppDelegate.swift EchoRecorderTests/Recovery
git commit -m "feat: add interrupted-session recovery detection on launch"
```

### Task 10: End-to-End Orchestration Test and Beta Checklist

**Files:**
- Create: `EchoRecorderTests/Integration/RecordingFlowIntegrationTests.swift`
- Create: `docs/testing/manual-qa-checklist.md`
- Create: `docs/testing/beta-release-checklist.md`

**Step 1: Write the failing test**

```swift
func testRecordingFlowIdleToFinalizeToIdle() async throws {
    let sut = TestHarness.makeCoordinatorWithFakes()
    try await sut.start(profile: .default)
    XCTAssertEqual(sut.state, .recording)
    try await sut.stop(name: "Sprint Review", overrideDirectory: nil)
    XCTAssertEqual(sut.state, .idle)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingFlowIntegrationTests`
Expected: FAIL until flow wiring is complete.

**Step 3: Write minimal implementation**

```swift
// Wire coordinator to capture, mixer, file writer, and finalizer.
// Ensure stop transitions through .stopping/.finalizing back to .idle.
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/RecordingFlowIntegrationTests`
Expected: PASS

**Step 5: Run full suite**

Run: `xcodebuild test -scheme EchoRecorder -destination 'platform=macOS'`
Expected: PASS all tests.

**Step 6: Commit**

```bash
git add EchoRecorderTests/Integration docs/testing/manual-qa-checklist.md docs/testing/beta-release-checklist.md
git commit -m "test: add end-to-end recording flow coverage and beta checklists"
```
