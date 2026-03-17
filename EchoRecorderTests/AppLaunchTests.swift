import XCTest
@testable import EchoRecorder

@MainActor
private final class FakeStatusItemController: StatusItemControlling {
    let configuredTitle: String

    init(configuredTitle: String) {
        self.configuredTitle = configuredTitle
    }
}

@MainActor
final class AppLaunchTests: XCTestCase {
    func testAppDelegateCreatesStatusItemController() {
        let fakeController = FakeStatusItemController(configuredTitle: "Injected")
        var factoryCallCount = 0
        var recoveryCheckCount = 0
        let appDelegate = AppDelegate(
            makeStatusItemController: {
                factoryCallCount += 1
                return fakeController
            },
            runLaunchRecoveryCheck: {
                recoveryCheckCount += 1
            }
        )

        XCTAssertNil(appDelegate.statusItemController)

        appDelegate.applicationDidFinishLaunching(Notification(name: Notification.Name("test")))

        XCTAssertEqual(factoryCallCount, 1)
        XCTAssertEqual(recoveryCheckCount, 1)
        XCTAssertNotNil(appDelegate.statusItemController)
        XCTAssertEqual(appDelegate.statusItemController?.configuredTitle, "Injected")
    }
}
