import XCTest
@testable import EchoRecorder

final class StatusItemVisualStateTests: XCTestCase {
    func testIdleAndPreparingMapToRecordingTapeWithoutPill() {
        let idle = statusItemVisualState(for: .idle, appName: "Echo")
        let preparing = statusItemVisualState(for: .preparing, appName: "Echo")

        XCTAssertEqual(idle.symbolName, "recordingtape")
        XCTAssertEqual(preparing.symbolName, "recordingtape")
        XCTAssertEqual(idle.symbolWeight, .medium)
        XCTAssertEqual(preparing.symbolWeight, .medium)
        XCTAssertFalse(idle.showRecordingPill)
        XCTAssertFalse(preparing.showRecordingPill)
    }

    func testRecordingMapsToRedRecordCircleWithPill() {
        let recording = statusItemVisualState(for: .recording, appName: "Echo")

        XCTAssertEqual(recording.symbolName, "record.circle.fill")
        XCTAssertTrue(recording.usesPaletteColor)
        XCTAssertTrue(recording.showRecordingPill)
    }

    func testFinalizingAndPendingFinalizeHidePill() {
        let finalizing = statusItemVisualState(for: .finalizing, appName: "Echo")
        let pending = statusItemVisualState(for: .pendingFinalize, appName: "Echo")

        XCTAssertEqual(finalizing.symbolName, "externaldrive.badge.checkmark")
        XCTAssertFalse(finalizing.showRecordingPill)
        XCTAssertFalse(pending.showRecordingPill)
    }
}
