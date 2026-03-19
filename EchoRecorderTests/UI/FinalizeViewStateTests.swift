import XCTest
@testable import EchoRecorder

@MainActor
final class FinalizeViewStateTests: XCTestCase {
    func testFinalizeViewPrimaryActionUsesSaveRecordingLabelAndStackedLayout() {
        XCTAssertEqual(FinalizeView.Copy.saveButtonTitle, "Save Recording")
        XCTAssertEqual(FinalizeView.Copy.changeLocationTitle, "Change Location")
        XCTAssertEqual(FinalizeView.Copy.nameFieldPlaceholder, "Recording name")
    }

    func testFinalizeViewSavingStateShowsInlineProgressCopySavingRecording() {
        let expectedCopy = "Saving recording..."
        XCTAssertEqual(FinalizeView.Copy.saveProgressTitle, expectedCopy)
    }

    func testFinalizeViewSuccessStateAppearsBeforeReset() {
        XCTAssertEqual(RecordingViewModel.FinalizeUIState.success, .success)
    }
}
