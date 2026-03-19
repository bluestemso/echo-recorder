import Foundation
import XCTest
@testable import EchoRecorder

@MainActor
final class RecordingRuntimeFlowTests: XCTestCase {
    func testToggleRecordingWithCoordinatorTransitionsToRecording() async {
        let coordinator = RecorderCoordinator(
            capture: FakeCaptureService(),
            mic: FakeMicService(),
            finalizer: FakeRecordingFinalizer(),
            permissionManager: AlwaysAuthorizedPermissionManager()
        )
        let viewModel = RecordingViewModel(recorderCoordinator: coordinator)

        viewModel.toggleRecording()

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(coordinator.state, .recording)
    }

    func testSecondToggleStopsAndShowsFinalizePrompt() async {
        let coordinator = RecorderCoordinator(
            capture: FakeCaptureService(),
            mic: FakeMicService(),
            finalizer: FakeRecordingFinalizer(),
            permissionManager: AlwaysAuthorizedPermissionManager()
        )
        let viewModel = RecordingViewModel(recorderCoordinator: coordinator)

        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(coordinator.state, .pendingFinalize)
        XCTAssertNotNil(viewModel.pendingFinalize)
    }

    func testConfirmFinalizeStoresOutputAndGoesIdle() async {
        let coordinator = RecorderCoordinator(
            capture: FakeCaptureService(),
            mic: FakeMicService(),
            finalizer: FakeRecordingFinalizer(),
            permissionManager: AlwaysAuthorizedPermissionManager()
        )
        let viewModel = RecordingViewModel(recorderCoordinator: coordinator)

        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.confirmFinalize()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertEqual(viewModel.lastFinalizedOutput?.mixed.lastPathComponent, "mixed.m4a")
    }

    func testFinalizeSuccessStateIsVisibleBeforeResetAndResetsRoughlyAfterOnePointFiveSeconds() async {
        let coordinator = RecorderCoordinator(
            capture: FakeCaptureService(),
            mic: FakeMicService(),
            finalizer: FakeRecordingFinalizer(),
            permissionManager: AlwaysAuthorizedPermissionManager()
        )
        let viewModel = RecordingViewModel(recorderCoordinator: coordinator)

        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let finalizeStart = Date()
        viewModel.confirmFinalize()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.finalizeUIState, .success)
        XCTAssertNotNil(viewModel.pendingFinalize)

        while viewModel.pendingFinalize != nil {
            try? await Task.sleep(nanoseconds: 50_000_000)
            if Date().timeIntervalSince(finalizeStart) > 2.0 {
                break
            }
        }

        let elapsed = Date().timeIntervalSince(finalizeStart)
        XCTAssertNil(viewModel.pendingFinalize)
        XCTAssertEqual(viewModel.finalizeUIState, .editing)
        XCTAssertEqual(elapsed, 1.5, accuracy: 0.2)
    }
}

@MainActor
private final class FakeCaptureService: CaptureServicing {
    private(set) var isRunning = false
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)?

    func startCapture(source: CaptureSourceDescriptor) async throws {
        isRunning = true
    }

    func stopCapture() async throws {
        isRunning = false
    }
}

private final class FakeMicService: MicCaptureServicing {
    private(set) var isCapturing = false
    var onMicSamples: ((MicSampleBuffer) -> Void)?

    func startCapture() throws {
        isCapturing = true
    }

    func stopCapture() throws {
        isCapturing = false
    }

    func selectDevice(_ device: AudioInputDevice) {}
}

private struct FakeRecordingFinalizer: RecordingFinalizing {
    func finalize(
        fileName: String,
        overrideDirectory: URL?,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput {
        let folder = URL(fileURLWithPath: "/tmp/echo-recorder-tests/runtime", isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a"),
            system: folder.appendingPathComponent("system_audio.m4a"),
            mic: folder.appendingPathComponent("mic_audio.m4a")
        )
    }
}

private struct AlwaysAuthorizedPermissionManager: PermissionManaging {
    func status(for permission: PermissionType) -> PermissionStatus {
        .authorized
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        .authorized
    }
}
