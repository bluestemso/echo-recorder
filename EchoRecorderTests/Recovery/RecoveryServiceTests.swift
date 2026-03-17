import Foundation
import XCTest
@testable import EchoRecorder

final class RecoveryServiceTests: XCTestCase {
    func testFindUnfinalizedManifestsReturnsOnlyUnfinalizedEntries() throws {
        let manifestsDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: manifestsDirectory) }

        try writeManifest(
            RecordingManifest(profileID: "default", recordingFileNames: ["take-1.m4a"], isFinalized: false),
            to: manifestsDirectory,
            named: "pending"
        )
        try writeManifest(
            RecordingManifest(profileID: "default", recordingFileNames: ["take-2.m4a"], isFinalized: true),
            to: manifestsDirectory,
            named: "done"
        )

        let service = RecoveryService(manifestsDirectory: manifestsDirectory)

        let manifestsNeedingRecovery = service.findUnfinalizedManifests()

        XCTAssertEqual(manifestsNeedingRecovery.count, 1)
        XCTAssertEqual(manifestsNeedingRecovery.first?.recordingFileNames, ["take-1.m4a"])
    }

    func testFindUnfinalizedManifestsDefaultsMissingIsFinalizedToFalse() throws {
        let manifestsDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: manifestsDirectory) }

        let rawManifest = """
        {
          "profileID": "default",
          "recordingFileNames": ["legacy.m4a"]
        }
        """
        let rawFileURL = manifestsDirectory.appendingPathComponent("legacy").appendingPathExtension("json")
        guard let rawManifestData = rawManifest.data(using: .utf8) else {
            XCTFail("Expected test fixture data to be valid UTF-8")
            return
        }
        try rawManifestData.write(to: rawFileURL, options: [.atomic])

        let service = RecoveryService(manifestsDirectory: manifestsDirectory)
        let manifestsNeedingRecovery = service.findUnfinalizedManifests()

        XCTAssertEqual(manifestsNeedingRecovery.count, 1)
        XCTAssertEqual(manifestsNeedingRecovery.first?.recordingFileNames, ["legacy.m4a"])
        XCTAssertEqual(manifestsNeedingRecovery.first?.isFinalized, false)
    }

    func testMalformedJSONDoesNotBlockValidManifestRecovery() throws {
        let manifestsDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: manifestsDirectory) }

        try writeManifest(
            RecordingManifest(profileID: "default", recordingFileNames: ["valid.m4a"], isFinalized: false),
            to: manifestsDirectory,
            named: "valid"
        )

        let malformedURL = manifestsDirectory.appendingPathComponent("bad").appendingPathExtension("json")
        try Data("{not-json}".utf8).write(to: malformedURL, options: [.atomic])

        var diagnostics: [String] = []
        let service = RecoveryService(manifestsDirectory: manifestsDirectory) { message in
            diagnostics.append(message)
        }

        let manifestsNeedingRecovery = service.findUnfinalizedManifests()

        XCTAssertEqual(manifestsNeedingRecovery.count, 1)
        XCTAssertEqual(manifestsNeedingRecovery.first?.recordingFileNames, ["valid.m4a"])
        XCTAssertEqual(diagnostics.count, 1)
    }

    func testFindUnfinalizedManifestsIgnoresNonJSONFiles() throws {
        let manifestsDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: manifestsDirectory) }

        try writeManifest(
            RecordingManifest(profileID: "default", recordingFileNames: ["valid.m4a"], isFinalized: false),
            to: manifestsDirectory,
            named: "valid"
        )

        let txtURL = manifestsDirectory.appendingPathComponent("notes").appendingPathExtension("txt")
        try Data("not-a-manifest".utf8).write(to: txtURL, options: [.atomic])

        let service = RecoveryService(manifestsDirectory: manifestsDirectory)
        let manifestsNeedingRecovery = service.findUnfinalizedManifests()

        XCTAssertEqual(manifestsNeedingRecovery.count, 1)
        XCTAssertEqual(manifestsNeedingRecovery.first?.recordingFileNames, ["valid.m4a"])
    }

    func testFindUnfinalizedManifestsReturnsEmptyWhenDirectoryMissing() {
        let missingDirectory = URL(fileURLWithPath: "/tmp/echo-recorder-tests/missing-\(UUID().uuidString)", isDirectory: true)
        var diagnostics: [String] = []
        let service = RecoveryService(manifestsDirectory: missingDirectory) { message in
            diagnostics.append(message)
        }

        let manifestsNeedingRecovery = service.findUnfinalizedManifests()

        XCTAssertTrue(manifestsNeedingRecovery.isEmpty)
        XCTAssertEqual(diagnostics.count, 1)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func writeManifest(_ manifest: RecordingManifest, to directory: URL, named key: String) throws {
        let fileURL = directory.appendingPathComponent(key).appendingPathExtension("json")
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: fileURL, options: [.atomic])
    }
}
