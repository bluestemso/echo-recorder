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

        try viewModel.finalizeRecording(fileName: "recording.m4a", overrideDirectory: nil)

        XCTAssertEqual(
            viewModel.finalizedURL,
            URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
                .appendingPathComponent("recording.m4a", isDirectory: false)
        )
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
