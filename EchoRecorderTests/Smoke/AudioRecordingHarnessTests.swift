import AVFoundation
import XCTest
@testable import EchoRecorder

@MainActor
final class AudioRecordingHarnessTests: XCTestCase {
    func testSyntheticHarnessProducesReadableM4AArtifacts() throws {
        let outputDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }

        let pipeline = AudioWriterPipeline(fileManager: .default)
        let frameCount = 48_000 * 2
        let systemSamples = makeSineWaveSamples(frequency: 440, frameCount: frameCount)
        let micSamples = makeSineWaveSamples(frequency: 220, frameCount: frameCount)
        let recordingData = RecordingAudioData(
            system: SystemAudioSampleBuffer(samples: systemSamples, sampleRate: 48_000, channelCount: 1),
            mic: MicSampleBuffer(samples: micSamples, sampleRate: 48_000, channelCount: 1)
        )

        let output = try pipeline.writeAudioOutputs(
            recordingName: "synthetic-harness",
            in: outputDirectory,
            recordingData: recordingData
        )

        let mixedDuration = try duration(of: output.mixed)
        let systemDuration = try duration(of: output.system)
        let micDuration = try duration(of: output.mic)

        XCTAssertGreaterThan(mixedDuration, 1.0)
        XCTAssertGreaterThan(systemDuration, 1.0)
        XCTAssertGreaterThan(micDuration, 1.0)

        print("[Harness] synthetic output folder=\(output.folder.path)")
        print("[Harness] synthetic durations mixed=\(mixedDuration) system=\(systemDuration) mic=\(micDuration)")
    }

    func testLiveHarnessProducesNonZeroDurationWhenEnabled() async throws {
        let markerURL = URL(fileURLWithPath: "/tmp/echo-run-live-harness")
        let shouldRunViaEnvironment = ProcessInfo.processInfo.environment["ECHO_RUN_LIVE_AUDIO_HARNESS"] == "1"
        let shouldRunViaMarker = FileManager.default.fileExists(atPath: markerURL.path)

        guard shouldRunViaEnvironment || shouldRunViaMarker else {
            throw XCTSkip("Enable via env ECHO_RUN_LIVE_AUDIO_HARNESS=1 or create /tmp/echo-run-live-harness")
        }

        let outputDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }

        let coordinator = RecorderCoordinator()
        let profile = Profile(
            id: "live-harness",
            name: "Live Harness",
            includeSystemAudio: true,
            micDeviceID: "default",
            captureMode: .audioOnly
        )

        try await coordinator.startAudioRecording(profile: profile)
        try await Task.sleep(nanoseconds: 4_000_000_000)

        let output = try await coordinator.stopAndFinalize(
            recordingName: "live-harness",
            overrideDirectory: outputDirectory
        )

        let mixedDuration = try duration(of: output.mixed)
        let systemDuration = try duration(of: output.system)
        let micDuration = try duration(of: output.mic)

        XCTAssertGreaterThan(mixedDuration, 0.5)
        XCTAssertGreaterThan(systemDuration, 0.5)
        XCTAssertGreaterThan(micDuration, 0.5)

        print("[Harness] live output folder=\(output.folder.path)")
        print("[Harness] live durations mixed=\(mixedDuration) system=\(systemDuration) mic=\(micDuration)")
    }

    private func duration(of fileURL: URL) throws -> Double {
        let file = try AVAudioFile(forReading: fileURL)
        guard file.processingFormat.sampleRate > 0 else {
            return 0
        }

        return Double(file.length) / file.processingFormat.sampleRate
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeSineWaveSamples(frequency: Float, frameCount: Int) -> [Float] {
        (0..<frameCount).map { index -> Float in
            let t = Float(index) / 48_000
            return sin(2 * .pi * frequency * t)
        }
    }
}
