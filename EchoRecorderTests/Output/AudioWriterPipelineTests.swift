import Foundation
import AVFoundation
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

    func testAudioWriterPipelineWritesMixedAndIsolatedFilesToDisk() throws {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempDirectory) }

        let pipeline = AudioWriterPipeline(fileManager: fileManager)
        let frameCount = 48_000
        let systemSamples = (0..<frameCount).map { index -> Float in
            let t = Float(index) / 48_000
            return sin(2 * .pi * 440 * t)
        }
        let micSamples = (0..<frameCount).map { index -> Float in
            let t = Float(index) / 48_000
            return sin(2 * .pi * 220 * t)
        }
        let recordingData = RecordingAudioData(
            system: SystemAudioSampleBuffer(samples: systemSamples, sampleRate: 48_000, channelCount: 1),
            mic: MicSampleBuffer(samples: micSamples, sampleRate: 48_000, channelCount: 1)
        )

        let output = try pipeline.writeAudioOutputs(
            recordingName: "real-audio-write",
            in: tempDirectory,
            recordingData: recordingData
        )

        XCTAssertTrue(fileManager.fileExists(atPath: output.mixed.path))
        XCTAssertTrue(fileManager.fileExists(atPath: output.system.path))
        XCTAssertTrue(fileManager.fileExists(atPath: output.mic.path))

        let mixedAttributes = try fileManager.attributesOfItem(atPath: output.mixed.path)
        let mixedSize = mixedAttributes[.size] as? NSNumber
        XCTAssertGreaterThan(mixedSize?.intValue ?? 0, 0)

        let mixedFile = try AVAudioFile(forReading: output.mixed)
        XCTAssertGreaterThan(mixedFile.length, 1000)
    }
}

private struct FakeAudioWriterPipeline: AudioWriterPipelining {
    func writeAudioOutputs(
        recordingName: String,
        in directory: URL,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput {
        let folder = directory.appendingPathComponent(recordingName, isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a"),
            system: folder.appendingPathComponent("system_audio.m4a"),
            mic: folder.appendingPathComponent("mic_audio.m4a")
        )
    }
}
