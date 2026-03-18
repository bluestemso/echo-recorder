import Foundation
import XCTest
@testable import EchoRecorder

@MainActor
final class RecordingFlowIntegrationTests: XCTestCase {
    func testAudioIntegrationFlowIdleToRecordingToFinalizeToIdle() async throws {
        let harness = AudioIntegrationHarness.makeWithFakes()

        try await harness.start()
        let output = try await harness.stopAndFinalize(name: "audio-mvp")

        XCTAssertEqual(harness.state, .idle)
        XCTAssertEqual(output.mixed.pathExtension, "m4a")
    }

    func testRecordingAndFinalizeFlowTransitionsIdleToRecordingToIdleAndProducesMixedAndIsolatedPaths() async throws {
        let harness = AudioIntegrationHarness.makeWithFakes()

        try await harness.start()
        let output = try await harness.stopAndFinalize(name: "integration-flow")

        XCTAssertEqual(harness.state, .idle)
        XCTAssertEqual(output.mixed.lastPathComponent, "mixed.m4a")
        XCTAssertEqual(output.system.lastPathComponent, "system_audio.m4a")
        XCTAssertEqual(output.mic.lastPathComponent, "mic_audio.m4a")
    }

    func testRecoveryFindsUnfinalizedAudioManifestAndIgnoresFinalizedManifest() throws {
        let manifestsDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: manifestsDirectory) }

        try writeManifest(
            RecordingManifest(
                profileID: "default",
                recordingFileNames: ["mixed.m4a", "system_audio.m4a", "mic_audio.m4a"],
                isFinalized: false
            ),
            to: manifestsDirectory,
            key: "pending"
        )
        try writeManifest(
            RecordingManifest(
                profileID: "default",
                recordingFileNames: ["mixed.m4a", "system_audio.m4a", "mic_audio.m4a"],
                isFinalized: true
            ),
            to: manifestsDirectory,
            key: "done"
        )

        let recovery = RecoveryService(manifestsDirectory: manifestsDirectory)
        let unfinalized = recovery.findUnfinalizedManifests()

        XCTAssertEqual(unfinalized.count, 1)
        XCTAssertEqual(unfinalized.first?.recordingFileNames, ["mixed.m4a", "system_audio.m4a", "mic_audio.m4a"])
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func writeManifest(_ manifest: RecordingManifest, to directory: URL, key: String) throws {
        let fileURL = directory.appendingPathComponent(key).appendingPathExtension("json")
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: fileURL, options: [.atomic])
    }
}

@MainActor
private struct AudioIntegrationHarness {
    private let coordinator: RecorderCoordinator

    var state: RecorderState {
        coordinator.state
    }

    static func makeWithFakes() -> AudioIntegrationHarness {
        AudioIntegrationHarness(
            coordinator: RecorderCoordinator(
                capture: FakeCaptureService(),
                mic: FakeMicService(),
                finalizer: FakeRecordingFinalizer(),
                permissionManager: AlwaysAuthorizedPermissionManager()
            )
        )
    }

    func start() async throws {
        try await coordinator.startAudioRecording(profile: .audioFixture)
    }

    func stopAndFinalize(name: String) async throws -> FinalizedAudioOutput {
        try await coordinator.stopAndFinalize(recordingName: name, overrideDirectory: nil)
    }
}

private extension Profile {
    static let audioFixture = Profile(id: "default", name: "Default")
}

@MainActor
private final class FakeCaptureService: CaptureServicing {
    private(set) var isRunning = false
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)?

    func startCapture(source: CaptureSourceDescriptor) async throws {
        isRunning = true
    }

    func stopCapture() async throws {
        isRunning = false
    }
}

private final class FakeMicService: MicCaptureServicing {
    private(set) var isCapturing = false
    var onMicSamples: ((MicSampleBuffer) -> Void)?

    func startCapture() throws {
        isCapturing = true
    }

    func stopCapture() throws {
        isCapturing = false
    }
}

private struct FakeRecordingFinalizer: RecordingFinalizing {
    func finalize(
        fileName: String,
        overrideDirectory: URL?,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput {
        let baseDirectory = overrideDirectory ?? URL(fileURLWithPath: "/tmp/echo-recorder-tests/integration", isDirectory: true)
        let folder = baseDirectory.appendingPathComponent(fileName, isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a", isDirectory: false),
            system: folder.appendingPathComponent("system_audio.m4a", isDirectory: false),
            mic: folder.appendingPathComponent("mic_audio.m4a", isDirectory: false)
        )
    }
}

private struct AlwaysAuthorizedPermissionManager: PermissionManaging {
    func status(for permission: PermissionType) -> PermissionStatus {
        .authorized
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        .authorized
    }
}
