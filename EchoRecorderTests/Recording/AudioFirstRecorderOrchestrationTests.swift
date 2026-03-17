import Foundation
import XCTest
@testable import EchoRecorder

@MainActor
final class AudioFirstRecorderOrchestrationTests: XCTestCase {
    func testStopFinalizesAudioAndReturnsToIdle() async throws {
        let fakeCapture = FakeCaptureService()
        let fakeMic = FakeMicService()
        let fakeFinalizer = FakeRecordingFinalizer()
        let sut = RecorderCoordinator(capture: fakeCapture, mic: fakeMic, finalizer: fakeFinalizer)

        try await sut.startAudioRecording(profile: .audioFixture)
        let output = try await sut.stopAndFinalize(recordingName: "demo", overrideDirectory: nil)

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(output.mixed.lastPathComponent, "mixed.m4a")
    }
}

private extension Profile {
    static let audioFixture = Profile(id: "default", name: "Default")
}

@MainActor
private final class FakeCaptureService: CaptureServicing {
    private(set) var isRunning = false

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
}

private struct FakeRecordingFinalizer: RecordingFinalizing {
    func finalize(fileName: String, overrideDirectory: URL?) throws -> FinalizedAudioOutput {
        let folder = URL(fileURLWithPath: "/tmp/echo-recorder-tests/finalized", isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a", isDirectory: false),
            system: folder.appendingPathComponent("system_audio.m4a", isDirectory: false),
            mic: folder.appendingPathComponent("mic_audio.m4a", isDirectory: false)
        )
    }
}
