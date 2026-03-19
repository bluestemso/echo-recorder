import XCTest
@testable import EchoRecorder

final class FinalizeTransitionTimingTests: XCTestCase {
    func testContentTransitionDurationUsesOneHundredFiftyMilliseconds() {
        XCTAssertEqual(PopoverUXTiming.contentTransitionDuration, 0.15, accuracy: 0.001)
        XCTAssertLessThanOrEqual(PopoverUXTiming.contentTransitionDuration, 0.2)
    }

    func testPostSaveResetDelayUsesOnePointFiveSeconds() {
        XCTAssertEqual(PopoverUXTiming.postSaveResetDelay, 1.5, accuracy: 0.001)
    }

    func testReduceMotionUsesOpacityOnlyPolicy() {
        XCTAssertEqual(PopoverContentTransitionPolicy.resolve(reduceMotion: true), .opacityOnly)
        XCTAssertEqual(PopoverContentTransitionPolicy.resolve(reduceMotion: false), .fadeAndMoveFromBottom)
    }
}
