import XCTest
@testable import EchoRecorder

final class PermissionManagerAudioTests: XCTestCase {
    func testRequestMicrophoneReturnsAuthorizedWhenProviderGrants() async {
        let manager = PermissionManager(
            statusProvider: { _ in .notDetermined },
            requestProvider: { permission in
                permission == .microphone ? .authorized : .denied
            }
        )

        let status = await manager.request(.microphone)
        XCTAssertEqual(status, .authorized)
    }
}
