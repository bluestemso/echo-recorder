import Combine
import XCTest
@testable import EchoRecorder

@MainActor
final class StatusItemControllerIconTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testIconUpdateLatencyWithin100ms() {
        let recorderCoordinator = RecorderCoordinator()
        let recordingRendered = expectation(description: "recording render event")
        var recordingRenderTimestamp = 0.0

        let controller = StatusItemController(
            title: "Echo",
            recorderCoordinator: recorderCoordinator,
            nowProvider: { Date().timeIntervalSince1970 },
            renderEventHandler: { event in
                guard event.state == .recording else {
                    return
                }

                recordingRenderTimestamp = event.timestamp
                recordingRendered.fulfill()
            }
        )

        let publicationTimestamp = Date().timeIntervalSince1970
        recorderCoordinator.startRecording()
        recorderCoordinator.markRecordingStarted()

        wait(for: [recordingRendered], timeout: 0.2)
        _ = controller

        let renderLatency = recordingRenderTimestamp - publicationTimestamp
        XCTAssertLessThanOrEqual(renderLatency, 0.1)
    }

    func testRecordingIndicatorUsesAppearanceAwareColorToken() {
        let light = StatusItemController.recordingIndicatorColor(for: NSAppearance(named: .aqua))
        let dark = StatusItemController.recordingIndicatorColor(for: NSAppearance(named: .darkAqua))

        XCTAssertNotEqual(light.redComponent, dark.redComponent)
        XCTAssertNotEqual(light.alphaComponent, dark.alphaComponent)
        XCTAssertGreaterThan(light.redComponent, light.greenComponent)
        XCTAssertGreaterThan(dark.redComponent, dark.greenComponent)
        XCTAssertGreaterThanOrEqual(light.alphaComponent, 0.7)
        XCTAssertGreaterThanOrEqual(dark.alphaComponent, 0.8)
    }

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

    func testPreparingAndFinalizingTriggerAnimationPlayback() {
        let preparingCoordinator = RecorderCoordinator()
        let preparingController = StatusItemController(
            title: "Echo",
            recorderCoordinator: preparingCoordinator
        )

        preparingCoordinator.startRecording()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(preparingController.latestRenderEvent?.state, .preparing)
        XCTAssertEqual(preparingController.latestRenderEvent?.animationMode, .finite)

        let finalizingCoordinator = RecorderCoordinator(initialState: .finalizing)
        let finalizingController = StatusItemController(
            title: "Echo",
            recorderCoordinator: finalizingCoordinator
        )
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(finalizingController.latestRenderEvent?.state, .finalizing)
        XCTAssertEqual(finalizingController.latestRenderEvent?.animationMode, .finite)
    }

    func testRecordingAnimationIsContinuousUntilStateExit() {
        let recorderCoordinator = RecorderCoordinator()
        let controller = StatusItemController(
            title: "Echo",
            recorderCoordinator: recorderCoordinator
        )

        recorderCoordinator.startRecording()
        recorderCoordinator.markRecordingStarted()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(controller.latestRenderEvent?.state, .recording)
        XCTAssertEqual(controller.latestRenderEvent?.animationMode, .continuous)

        recorderCoordinator.stopRecording()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(controller.latestRenderEvent?.state, .idle)
        XCTAssertNotEqual(controller.latestRenderEvent?.animationMode, .continuous)
    }

    func testFinalizingStateRemainsVisibleBeforeReturningToIdle() {
        let recorderCoordinator = RecorderCoordinator(initialState: .finalizing)
        let controller = StatusItemController(
            title: "Echo",
            recorderCoordinator: recorderCoordinator
        )

        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        XCTAssertEqual(controller.latestRenderEvent?.state, .finalizing)

        recorderCoordinator.stopRecording()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(controller.latestRenderEvent?.state, .finalizing)

        RunLoop.main.run(until: Date().addingTimeInterval(0.75))
        XCTAssertEqual(controller.latestRenderEvent?.state, .idle)
    }

    func testPopoverPolicyUsesExplicitFadeTiming() {
        XCTAssertEqual(PopoverAnimationPolicy.fadeDuration(for: .show), 0.075, accuracy: 0.001)
        XCTAssertEqual(PopoverAnimationPolicy.fadeDuration(for: .close), 0.075, accuracy: 0.001)
        XCTAssertFalse(PopoverAnimationPolicy.usesSystemPopoverAnimation)
    }
}
