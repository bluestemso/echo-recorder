import XCTest
@testable import EchoRecorder

final class JSONStoreTests: XCTestCase {
    func testJSONStoreRoundTripsProfile() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let store = JSONStore(baseDirectory: temporaryDirectory)
        let expectedProfile = Profile(id: "default", name: "Default")

        try store.save(expectedProfile, as: "profile")
        let loadedProfile: Profile = try store.load(Profile.self, from: "profile")

        XCTAssertEqual(loadedProfile, expectedProfile)
    }

    func testLoadMissingFileThrowsLoadFailed() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = JSONStore(baseDirectory: temporaryDirectory)

        XCTAssertThrowsError(try store.load(Profile.self, from: "missing")) { error in
            guard case JSONStoreError.loadFailed(let key, _) = error else {
                XCTFail("Expected loadFailed for missing file")
                return
            }
            XCTAssertEqual(key, "missing")
        }
    }

    func testInvalidKeyThrowsInvalidKeyError() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = JSONStore(baseDirectory: temporaryDirectory)

        XCTAssertThrowsError(try store.save(Profile(id: "default", name: "Default"), as: "../profile")) { error in
            guard case JSONStoreError.invalidKey(let key) = error else {
                XCTFail("Expected invalidKey error")
                return
            }
            XCTAssertEqual(key, "../profile")
        }
    }

    func testMalformedJSONThrowsLoadFailed() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let malformedFileURL = temporaryDirectory.appendingPathComponent("profile").appendingPathExtension("json")
        guard let malformedData = "not-json".data(using: .utf8) else {
            XCTFail("Expected test fixture data to be valid UTF-8")
            return
        }
        try malformedData.write(to: malformedFileURL)

        let store = JSONStore(baseDirectory: temporaryDirectory)
        XCTAssertThrowsError(try store.load(Profile.self, from: "profile")) { error in
            guard case JSONStoreError.loadFailed(let key, _) = error else {
                XCTFail("Expected loadFailed for malformed JSON")
                return
            }
            XCTAssertEqual(key, "profile")
        }
    }

    func testSaveOverwritesExistingValue() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = JSONStore(baseDirectory: temporaryDirectory)

        try store.save(Profile(id: "default", name: "First"), as: "profile")
        try store.save(Profile(id: "default", name: "Second"), as: "profile")

        let loadedProfile: Profile = try store.load(Profile.self, from: "profile")
        XCTAssertEqual(loadedProfile.name, "Second")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        return temporaryDirectory
    }
}
