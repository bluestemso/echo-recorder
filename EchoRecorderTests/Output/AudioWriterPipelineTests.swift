import Foundation
import XCTest
@testable import EchoRecorder

final class AudioWriterPipelineTests: XCTestCase {
    func testFinalizeReturnsMixedAndIsolatedAudioArtifactPaths() throws {
        let pipeline = FakeAudioWriterPipeline()
        let temp = URL(fileURLWithPath: "/tmp/echo-recorder-tests/output", isDirectory: true)
        let finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(pipeline: pipeline),
            defaultDirectory: temp
        )

        let output = try finalizer.finalize(fileName: "standup", overrideDirectory: nil)

        XCTAssertEqual(output.mixed.lastPathComponent, "mixed.m4a")
        XCTAssertEqual(output.system.lastPathComponent, "system_audio.m4a")
        XCTAssertEqual(output.mic.lastPathComponent, "mic_audio.m4a")
    }
}

private struct FakeAudioWriterPipeline: AudioWriterPipelining {
    func writeAudioOutputs(recordingName: String, in directory: URL) throws -> FinalizedAudioOutput {
        let folder = directory.appendingPathComponent(recordingName, isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a"),
            system: folder.appendingPathComponent("system_audio.m4a"),
            mic: folder.appendingPathComponent("mic_audio.m4a")
        )
    }
}
