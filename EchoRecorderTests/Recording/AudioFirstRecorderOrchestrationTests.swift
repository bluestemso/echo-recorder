import Foundation
import XCTest
@testable import EchoRecorder

@MainActor
final class AudioFirstRecorderOrchestrationTests: XCTestCase {
    func testStopFinalizesAudioAndReturnsToIdle() async throws {
        let fakeCapture = FakeCaptureService()
        let fakeMic = FakeMicService()
        let fakeFinalizer = FakeRecordingFinalizer()
        let sut = RecorderCoordinator(
            capture: fakeCapture,
            mic: fakeMic,
            finalizer: fakeFinalizer,
            permissionManager: AlwaysAuthorizedPermissionManager()
        )

        try await sut.startAudioRecording(profile: .audioFixture)
        let output = try await sut.stopAndFinalize(recordingName: "demo", overrideDirectory: nil)

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(output.mixed.lastPathComponent, "mixed.m4a")
    }

    func testStopAndFinalizeForwardsCapturedSystemAndMicSamples() async throws {
        let fakeCapture = FakeCaptureService()
        let fakeMic = FakeMicService()
        let fakeFinalizer = CapturingRecordingFinalizer()
        let sut = RecorderCoordinator(
            capture: fakeCapture,
            mic: fakeMic,
            finalizer: fakeFinalizer,
            permissionManager: AlwaysAuthorizedPermissionManager()
        )

        try await sut.startAudioRecording(profile: .audioFixture)
        fakeCapture.emit(samples: [0.3, -0.2])
        fakeMic.emit(samples: [0.1, -0.1])
        _ = try await sut.stopAndFinalize(recordingName: "demo", overrideDirectory: nil)

        let captured = fakeFinalizer.lastRecordingData
        XCTAssertEqual(captured?.system.samples, [0.3, -0.2])
        XCTAssertEqual(captured?.mic.samples, [0.1, -0.1])
    }

    func testStartAudioRecordingRequestsMicrophoneAndScreenPermissions() async throws {
        let permissionManager = TrackingPermissionManager(
            statuses: [.microphone: .notDetermined, .screenRecording: .notDetermined],
            requestStatuses: [.microphone: .authorized, .screenRecording: .authorized]
        )
        let sut = RecorderCoordinator(
            capture: FakeCaptureService(),
            mic: FakeMicService(),
            finalizer: FakeRecordingFinalizer(),
            permissionManager: permissionManager
        )

        try await sut.startAudioRecording(profile: .audioFixture)

        XCTAssertEqual(permissionManager.requestedPermissions, [.microphone, .screenRecording])
    }
}

private extension Profile {
    static let audioFixture = Profile(id: "default", name: "Default")
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

    func emit(samples: [Float]) {
        onSystemAudioSamples?(
            SystemAudioSampleBuffer(samples: samples, sampleRate: 48_000, channelCount: 1)
        )
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

    func emit(samples: [Float]) {
        onMicSamples?(MicSampleBuffer(samples: samples, sampleRate: 48_000, channelCount: 1))
    }
}

private struct FakeRecordingFinalizer: RecordingFinalizing {
    func finalize(
        fileName: String,
        overrideDirectory: URL?,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput {
        let folder = URL(fileURLWithPath: "/tmp/echo-recorder-tests/finalized", isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a", isDirectory: false),
            system: folder.appendingPathComponent("system_audio.m4a", isDirectory: false),
            mic: folder.appendingPathComponent("mic_audio.m4a", isDirectory: false)
        )
    }
}

@MainActor
private final class CapturingRecordingFinalizer: RecordingFinalizing {
    private(set) var lastRecordingData: RecordingAudioData?

    func finalize(
        fileName: String,
        overrideDirectory: URL?,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput {
        lastRecordingData = recordingData
        let folder = URL(fileURLWithPath: "/tmp/echo-recorder-tests/finalized", isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a", isDirectory: false),
            system: folder.appendingPathComponent("system_audio.m4a", isDirectory: false),
            mic: folder.appendingPathComponent("mic_audio.m4a", isDirectory: false)
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

private final class TrackingPermissionManager: PermissionManaging {
    private let statuses: [PermissionType: PermissionStatus]
    private let requestStatuses: [PermissionType: PermissionStatus]
    private(set) var requestedPermissions: [PermissionType] = []

    init(
        statuses: [PermissionType: PermissionStatus],
        requestStatuses: [PermissionType: PermissionStatus]
    ) {
        self.statuses = statuses
        self.requestStatuses = requestStatuses
    }

    func status(for permission: PermissionType) -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        requestedPermissions.append(permission)
        return requestStatuses[permission] ?? .denied
    }
}
