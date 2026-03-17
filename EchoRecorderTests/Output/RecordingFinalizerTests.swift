import Foundation
import XCTest
@testable import EchoRecorder

final class RecordingFinalizerTests: XCTestCase {
    func testFinalizeUsesDefaultDirectoryWhenOverrideIsNil() throws {
        let fileWriter = FileWriterService()
        let defaultDirectory = URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        let finalizer = RecordingFinalizer(fileWriter: fileWriter, defaultDirectory: defaultDirectory)

        let output = try finalizer.finalize(fileName: "recording", overrideDirectory: nil)

        XCTAssertEqual(output.folder, defaultDirectory.appendingPathComponent("recording", isDirectory: true))
        XCTAssertEqual(output.mixed.lastPathComponent, "mixed.m4a")
        XCTAssertEqual(output.system.lastPathComponent, "system_audio.m4a")
        XCTAssertEqual(output.mic.lastPathComponent, "mic_audio.m4a")
    }

    func testFinalizeUsesOverrideDirectoryWhenProvided() throws {
        let fileWriter = FileWriterService()
        let defaultDirectory = URL(fileURLWithPath: "/tmp/echo-recorder-tests/default", isDirectory: true)
        let overrideDirectory = URL(fileURLWithPath: "/tmp/echo-recorder-tests/override", isDirectory: true)
        let finalizer = RecordingFinalizer(fileWriter: fileWriter, defaultDirectory: defaultDirectory)

        let output = try finalizer.finalize(fileName: "recording", overrideDirectory: overrideDirectory)

        XCTAssertEqual(output.folder, overrideDirectory.appendingPathComponent("recording", isDirectory: true))
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
