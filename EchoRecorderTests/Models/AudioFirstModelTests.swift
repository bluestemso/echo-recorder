import XCTest
@testable import EchoRecorder

final class AudioFirstModelTests: XCTestCase {
    func testProfileDefaultsToAudioOnlyMVP() {
        let profile = Profile(id: "default", name: "Default")

        XCTAssertTrue(profile.includeSystemAudio)
        XCTAssertNotNil(profile.micDeviceID)
        XCTAssertEqual(profile.captureMode, .audioOnly)
    }
}
