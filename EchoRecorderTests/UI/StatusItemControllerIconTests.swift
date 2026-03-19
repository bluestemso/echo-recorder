import XCTest
@testable import EchoRecorder

@MainActor
final class StatusItemControllerIconTests: XCTestCase {
    func testRecordingStateSetsAccessibilityLabel() {
        let recorderCoordinator = RecorderCoordinator()
        let controller = StatusItemController(
            title: "Echo",
            recorderCoordinator: recorderCoordinator
        )

        recorderCoordinator.startRecording()
        recorderCoordinator.markRecordingStarted()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(controller.statusItem.button?.accessibilityLabel(), "Echo recording")
    }
}
