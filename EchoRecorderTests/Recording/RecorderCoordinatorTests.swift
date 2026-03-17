import XCTest
@testable import EchoRecorder

@MainActor
final class RecorderCoordinatorTests: XCTestCase {
    func testStartRecordingFromIdleTransitionsToPreparing() {
        let coordinator = RecorderCoordinator()

        coordinator.startRecording()

        XCTAssertEqual(coordinator.state, .preparing)
    }

    func testStartRecordingWhileRecordingIsIgnored() {
        let coordinator = RecorderCoordinator(initialState: .recording)

        coordinator.startRecording()

        XCTAssertEqual(coordinator.state, .recording)
    }
}
