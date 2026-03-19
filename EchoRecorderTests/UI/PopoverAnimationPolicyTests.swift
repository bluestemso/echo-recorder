import XCTest
@testable import EchoRecorder

final class PopoverAnimationPolicyTests: XCTestCase {
    func testPopoverFadeDurationUsesSeventyFiveMillisecondsForShowAndClose() {
        XCTAssertEqual(PopoverAnimationPolicy.fadeDuration(for: .show), 0.075, accuracy: 0.001)
        XCTAssertEqual(PopoverAnimationPolicy.fadeDuration(for: .close), 0.075, accuracy: 0.001)
    }

    func testPopoverDisablesDefaultSystemAnimation() {
        XCTAssertFalse(PopoverAnimationPolicy.usesSystemPopoverAnimation)
    }
}
