import Foundation
import XCTest
@testable import EchoRecorder

final class RecordingFinalizerTests: XCTestCase {
    func testFinalizeUsesDefaultDirectoryWhenOverrideIsNil() throws {
        let fileWriter = FileWriterService()
        let defaultDirectory = URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        let finalizer = RecordingFinalizer(fileWriter: fileWriter, defaultDirectory: defaultDirectory)

        let outputURL = try finalizer.finalize(fileName: "recording.m4a", overrideDirectory: nil)

        XCTAssertEqual(outputURL, defaultDirectory.appendingPathComponent("recording.m4a", isDirectory: false))
    }

    func testFinalizeUsesOverrideDirectoryWhenProvided() throws {
        let fileWriter = FileWriterService()
        let defaultDirectory = URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        let overrideDirectory = URL(fileURLWithPath: "/tmp/echo-recorder-tests/override", isDirectory: true)
        let finalizer = RecordingFinalizer(fileWriter: fileWriter, defaultDirectory: defaultDirectory)

        let outputURL = try finalizer.finalize(fileName: "recording.m4a", overrideDirectory: overrideDirectory)

        XCTAssertEqual(outputURL, overrideDirectory.appendingPathComponent("recording.m4a", isDirectory: false))
    }

    func testFinalizeThrowsForEmptyFileName() {
        let finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        )

        XCTAssertThrowsError(try finalizer.finalize(fileName: "   ", overrideDirectory: nil)) { error in
            guard case RecordingFinalizerError.emptyFileName = error else {
                XCTFail("Expected emptyFileName error")
                return
            }
        }
    }

    func testFinalizeThrowsForInvalidFileNamePathSeparator() {
        let finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        )

        XCTAssertThrowsError(try finalizer.finalize(fileName: "folder/recording.m4a", overrideDirectory: nil)) { error in
            guard case RecordingFinalizerError.invalidFileName(let badName) = error else {
                XCTFail("Expected invalidFileName error")
                return
            }

            XCTAssertEqual(badName, "folder/recording.m4a")
        }
    }
}
