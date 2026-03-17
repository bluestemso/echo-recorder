import Foundation
import XCTest
@testable import EchoRecorder

@MainActor
final class RecordingFlowIntegrationTests: XCTestCase {
    func testRecordingAndFinalizeFlowTransitionsIdleToRecordingToIdleAndProducesOutputPath() throws {
        let defaultDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: defaultDirectory) }

        let coordinator = RecorderCoordinator()
        let recordingViewModel = RecordingViewModel(recorderCoordinator: coordinator)
        let finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: defaultDirectory
        )
        let finalizeViewModel = FinalizeRecordingViewModel(finalizer: finalizer)

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertFalse(recordingViewModel.isRecording)

        recordingViewModel.toggleRecording()
        coordinator.markRecordingStarted()

        XCTAssertEqual(coordinator.state, .recording)
        XCTAssertTrue(recordingViewModel.isRecording)

        recordingViewModel.toggleRecording()

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertFalse(recordingViewModel.isRecording)

        try finalizeViewModel.finalizeRecording(fileName: "integration-flow.m4a", overrideDirectory: nil)

        let expectedURL = defaultDirectory.appendingPathComponent("integration-flow.m4a", isDirectory: false)
        XCTAssertEqual(finalizeViewModel.finalizedURL, expectedURL)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
