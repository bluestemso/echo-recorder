import XCTest
@testable import EchoRecorder

@MainActor
final class SystemAudioCaptureTests: XCTestCase {
    func testStartSystemAudioCapturePublishesSampleCallback() async throws {
        let adapter = FakeSystemAudioAdapter()
        let service = CaptureService(adapter: adapter)
        var callbackCount = 0

        service.onSystemAudioSamples = { _ in callbackCount += 1 }

        try await service.startCapture(source: .systemAudio)
        adapter.emitFakeAudioFrame()

        XCTAssertEqual(callbackCount, 1)
    }
}

@MainActor
private final class FakeSystemAudioAdapter: ScreenCaptureKitAdapting {
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)?

    func startCapture(source: CaptureSourceDescriptor) async throws {}

    func stopCapture() async throws {}

    func emitFakeAudioFrame() {
        let fakeBuffer = SystemAudioSampleBuffer(
            samples: [0.1, -0.1, 0.25],
            sampleRate: 48_000,
            channelCount: 1
        )
        onSystemAudioSamples?(fakeBuffer)
    }
}
