import XCTest
@testable import EchoRecorder

@MainActor
final class FinalizeViewStateTests: XCTestCase {
    func testFinalizeViewPrimaryActionUsesSaveRecordingLabelAndStackedLayout() {
        XCTFail("TODO: finalize-first stacked action hierarchy with full-width Save Recording button")
    }

    func testFinalizeViewSavingStateShowsInlineProgressCopySavingRecording() {
        let expectedCopy = "Saving recording..."
        XCTAssertEqual(expectedCopy, "Saving recording...")
        XCTFail("TODO: saving state should render spinner + \(expectedCopy) and disable duplicate save")
    }

    func testFinalizeViewSuccessStateAppearsBeforeReset() {
        XCTFail("TODO: success morph state should be visible before delayed reset")
    }
}
