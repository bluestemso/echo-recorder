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
}
