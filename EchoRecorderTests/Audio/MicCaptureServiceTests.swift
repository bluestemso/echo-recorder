import XCTest
@testable import EchoRecorder

final class MicCaptureServiceTests: XCTestCase {
    func testStartAndStopToggleCaptureState() throws {
        let service = MicCaptureService()

        XCTAssertFalse(service.isCapturing)

        try service.startCapture()
        XCTAssertTrue(service.isCapturing)

        try service.stopCapture()
        XCTAssertFalse(service.isCapturing)
    }

    func testStartCaptureWhileCapturingThrowsAlreadyCapturing() throws {
        let service = MicCaptureService()
        try service.startCapture()

        XCTAssertThrowsError(try service.startCapture()) { error in
            guard case MicCaptureServiceError.alreadyCapturing = error else {
                XCTFail("Expected alreadyCapturing error")
                return
            }
        }
    }

    func testStopCaptureWhileNotCapturingThrowsNotCapturing() {
        let service = MicCaptureService()

        XCTAssertThrowsError(try service.stopCapture()) { error in
            guard case MicCaptureServiceError.notCapturing = error else {
                XCTFail("Expected notCapturing error")
                return
            }
        }
    }
}
