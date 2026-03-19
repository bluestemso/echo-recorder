import XCTest
@testable import EchoRecorder

@MainActor
final class RecordingViewModelTests: XCTestCase {
    func testSourceLevelsMapToDisplayRowsInStableOrder() {
        let viewModel = RecordingViewModel()

        viewModel.updateLevels([
            .microphone: SourceLevel(peak: 0.2, rms: 0.1),
            .system: SourceLevel(peak: 0.6, rms: 0.4)
        ])

        XCTAssertEqual(viewModel.levelRows.count, 2)
        XCTAssertEqual(viewModel.levelRows.map(\.title), ["System Audio", "Microphone"])
        XCTAssertEqual(viewModel.levelRows[0].level, SourceLevel(peak: 0.6, rms: 0.4))
        XCTAssertEqual(viewModel.levelRows[1].level, SourceLevel(peak: 0.2, rms: 0.1))
    }

    func testBindRecorderStateUpdatesRecordingFlagsAndTitle() {
        let viewModel = RecordingViewModel()

        viewModel.bindRecorderState(.idle)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.primaryActionTitle, "Start Recording")

        viewModel.bindRecorderState(.preparing)
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertEqual(viewModel.primaryActionTitle, "Stop Recording")

        viewModel.bindRecorderState(.recording)
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertEqual(viewModel.primaryActionTitle, "Stop Recording")
    }

    func testToggleRecordingInvokesStartAndStopCallbacks() {
        var startCallCount = 0
        var stopCallCount = 0
        let viewModel = RecordingViewModel(
            onStartRecording: { startCallCount += 1 },
            onStopRecording: { stopCallCount += 1 }
        )

        viewModel.toggleRecording()
        XCTAssertEqual(startCallCount, 1)
        XCTAssertEqual(stopCallCount, 0)

        viewModel.bindRecorderState(.recording)
        viewModel.toggleRecording()
        XCTAssertEqual(startCallCount, 1)
        XCTAssertEqual(stopCallCount, 1)
    }

    func testUpdateLevelsFallsBackToZeroForMissingSources() {
        let viewModel = RecordingViewModel()

        viewModel.updateLevels([
            .system: SourceLevel(peak: 0.5, rms: 0.25)
        ])

        XCTAssertEqual(viewModel.levelRows.count, 2)
        XCTAssertEqual(viewModel.levelRows[0].source, .system)
        XCTAssertEqual(viewModel.levelRows[0].level, SourceLevel(peak: 0.5, rms: 0.25))
        XCTAssertEqual(viewModel.levelRows[1].source, .microphone)
        XCTAssertEqual(viewModel.levelRows[1].level, .zero)
    }

    func testApplyMeterSnapshotMaintainsStableOrder() {
        let viewModel = RecordingViewModel()

        viewModel.setGain(1.0, for: .system)
        viewModel.setGain(1.0, for: .microphone)
        viewModel.applyMeterSnapshot(
            system: SourceLevel(peak: 0.9, rms: 0.7),
            mic: SourceLevel(peak: 0.3, rms: 0.2)
        )

        XCTAssertEqual(viewModel.levelRows.map(\.source), [.system, .microphone])
    }

    func testLevelRowsResetToZeroWhenRecordingTransitionsToIdle() {
        let viewModel = RecordingViewModel()
        viewModel.setGain(1.0, for: .system)
        viewModel.setGain(1.0, for: .microphone)
        viewModel.applyMeterSnapshot(
            system: SourceLevel(peak: 0.9, rms: 0.7),
            mic: SourceLevel(peak: 0.5, rms: 0.3)
        )
        XCTAssertGreaterThan(viewModel.levelRows[0].level.peak, 0)

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

    func testConfirmFinalizeUsesEditedPendingFinalizeNameForFinalizeCall() async {
        let finalizer = RecordingNameCapturingFinalizer()
        let coordinator = RecorderCoordinator(
            capture: ViewModelTestCaptureService(),
            mic: ViewModelTestMicService(),
            finalizer: finalizer,
            permissionManager: ViewModelTestAlwaysAuthorizedPermissionManager()
        )
        let viewModel = RecordingViewModel(recorderCoordinator: coordinator)

        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.toggleRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let editedName = "Weekly Standup - Edited"
        viewModel.pendingFinalizeName = editedName

        viewModel.confirmFinalize()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(finalizer.lastFileName, editedName)
    }
}

@MainActor
private final class ViewModelTestCaptureService: CaptureServicing {
    private(set) var isRunning = false
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)?

    func startCapture(source: CaptureSourceDescriptor) async throws {
        isRunning = true
    }

    func stopCapture() async throws {
        isRunning = false
    }
}

private final class ViewModelTestMicService: MicCaptureServicing {
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

private final class RecordingNameCapturingFinalizer: RecordingFinalizing {
    private(set) var lastFileName: String?

    func finalize(
        fileName: String,
        overrideDirectory: URL?,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput {
        lastFileName = fileName
        let folder = URL(fileURLWithPath: "/tmp/echo-recorder-tests/view-model", isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a"),
            system: folder.appendingPathComponent("system_audio.m4a"),
            mic: folder.appendingPathComponent("mic_audio.m4a")
        )
    }
}

private struct ViewModelTestAlwaysAuthorizedPermissionManager: PermissionManaging {
    func status(for permission: PermissionType) -> PermissionStatus {
        .authorized
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        .authorized
    }
}
