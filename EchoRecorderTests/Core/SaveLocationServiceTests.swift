import XCTest
import Foundation
@testable import EchoRecorder

final class SaveLocationServiceTests: XCTestCase {
    private var tempDirectory: URL!
    private var store: JSONStore!
    private var service: SaveLocationService!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveLocationServiceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        store = JSONStore(baseDirectory: tempDirectory)
        service = SaveLocationService(store: store)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testLoadReturnsFallbackWhenNothingPersisted() {
        let loaded = service.load()
        XCTAssertEqual(loaded, SaveLocationService.defaultFallback)
    }

    func testSaveAndLoadRoundTrip() throws {
        let target = URL(fileURLWithPath: "/tmp/echo-test-recordings", isDirectory: true)
        try service.save(target)
        let loaded = service.load()
        XCTAssertEqual(loaded.path, target.path)
    }
}
