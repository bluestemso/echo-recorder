import XCTest
@testable import EchoRecorder

final class MicCaptureTapTests: XCTestCase {
    func testStartCaptureInstallsTapAndEmitsMicSamples() throws {
        let engine = FakeAudioEngine()
        let service = MicCaptureService(engine: engine)
        var sampleEvents = 0

        service.onMicSamples = { _ in sampleEvents += 1 }

        try service.startCapture()
        engine.emitFakeInputBuffer()

        XCTAssertEqual(sampleEvents, 1)
    }
}

private final class FakeAudioEngine: MicCaptureEngine {
    var isStarted = false
    private var tapHandler: ((MicSampleBuffer) -> Void)?

    func installTap(_ handler: @escaping (MicSampleBuffer) -> Void) {
        tapHandler = handler
    }

    func removeTap() {
        tapHandler = nil
    }

    func start() throws {
        isStarted = true
    }

    func stop() {
        isStarted = false
    }

    func emitFakeInputBuffer() {
        tapHandler?(
            MicSampleBuffer(samples: [0.2, -0.2], sampleRate: 48_000, channelCount: 1)
        )
    }
}
