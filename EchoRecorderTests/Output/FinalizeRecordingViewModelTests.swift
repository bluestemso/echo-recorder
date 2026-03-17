import Foundation
import XCTest
@testable import EchoRecorder

@MainActor
final class FinalizeRecordingViewModelTests: XCTestCase {
    func testFinalizeRecordingSetsFinalizedURLOnSuccess() throws {
        let finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        )
        let viewModel = FinalizeRecordingViewModel(finalizer: finalizer)

        try viewModel.finalizeRecording(fileName: "recording", overrideDirectory: nil)

        XCTAssertEqual(
            viewModel.finalizedURL,
            URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
                .appendingPathComponent("recording", isDirectory: true)
                .appendingPathComponent("mixed.m4a", isDirectory: false)
        )
        XCTAssertEqual(viewModel.finalizedOutput?.system.lastPathComponent, "system_audio.m4a")
        XCTAssertEqual(viewModel.finalizedOutput?.mic.lastPathComponent, "mic_audio.m4a")
    }

    func testFinalizeRecordingLeavesFinalizedURLUnsetOnError() {
        let finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        )
        let viewModel = FinalizeRecordingViewModel(finalizer: finalizer)

        XCTAssertThrowsError(try viewModel.finalizeRecording(fileName: "../bad-name", overrideDirectory: nil))
        XCTAssertNil(viewModel.finalizedURL)
    }
}
