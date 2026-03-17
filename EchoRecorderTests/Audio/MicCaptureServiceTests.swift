import XCTest
@testable import EchoRecorder

final class MicCaptureServiceTests: XCTestCase {
    func testStartAndStopToggleCaptureState() throws {
        let service = MicCaptureService(engine: FakeMicEngine())

        XCTAssertFalse(service.isCapturing)

        try service.startCapture()
        XCTAssertTrue(service.isCapturing)

        try service.stopCapture()
        XCTAssertFalse(service.isCapturing)
    }

    func testStartCaptureWhileCapturingThrowsAlreadyCapturing() throws {
        let service = MicCaptureService(engine: FakeMicEngine())
        try service.startCapture()

        XCTAssertThrowsError(try service.startCapture()) { error in
            guard case MicCaptureServiceError.alreadyCapturing = error else {
                XCTFail("Expected alreadyCapturing error")
                return
            }
        }
    }

    func testStopCaptureWhileNotCapturingThrowsNotCapturing() {
        let service = MicCaptureService(engine: FakeMicEngine())

        XCTAssertThrowsError(try service.stopCapture()) { error in
            guard case MicCaptureServiceError.notCapturing = error else {
                XCTFail("Expected notCapturing error")
                return
            }
        }
    }
}

private final class FakeMicEngine: MicCaptureEngine {
    func installTap(_ handler: @escaping (MicSampleBuffer) -> Void) {}

    func removeTap() {}

    func start() throws {}

    func stop() {}
}
