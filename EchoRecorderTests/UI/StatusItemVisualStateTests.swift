import XCTest
@testable import EchoRecorder

final class StatusItemVisualStateTests: XCTestCase {
    func testIdleAndPreparingUseRecordingTapeSymbol() {
        let appName = "Echo"

        assertVisualState(
            statusItemVisualState(for: .idle, appName: appName),
            symbolName: "recordingtape",
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "Echo idle",
            isAnimated: false
        )

        assertVisualState(
            statusItemVisualState(for: .preparing, appName: appName),
            symbolName: "recordingtape",
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "Echo preparing",
            isAnimated: true
        )
    }

    func testRecordingUsesRedRecordCircleFill() {
        let recording = statusItemVisualState(for: .recording, appName: "Echo")

        assertVisualState(
            recording,
            symbolName: "record.circle.fill",
            showRecordingPill: true,
            usesPaletteColor: true,
            accessibilityLabel: "Echo recording",
            isAnimated: true
        )
    }

    func testAllRecorderStatesMapToExpectedVisualState() {
        let appName = "EchoRecorder"

        assertVisualState(
            statusItemVisualState(for: .idle, appName: appName),
            symbolName: "recordingtape",
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "EchoRecorder idle",
            isAnimated: false
        )
        assertVisualState(
            statusItemVisualState(for: .preparing, appName: appName),
            symbolName: "recordingtape",
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "EchoRecorder preparing",
            isAnimated: true
        )
        assertVisualState(
            statusItemVisualState(for: .recording, appName: appName),
            symbolName: "record.circle.fill",
            showRecordingPill: true,
            usesPaletteColor: true,
            accessibilityLabel: "EchoRecorder recording",
            isAnimated: true
        )
        assertVisualState(
            statusItemVisualState(for: .pendingFinalize, appName: appName),
            symbolName: "recordingtape",
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "EchoRecorder pending finalize",
            isAnimated: false
        )
        assertVisualState(
            statusItemVisualState(for: .finalizing, appName: appName),
            symbolName: "externaldrive.badge.checkmark",
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "EchoRecorder finalizing",
            isAnimated: true
        )
    }

    func testRecordingShowsRedPillOnly() {
        XCTAssertTrue(statusItemVisualState(for: .recording, appName: "Echo").showRecordingPill)
        XCTAssertFalse(statusItemVisualState(for: .idle, appName: "Echo").showRecordingPill)
        XCTAssertFalse(statusItemVisualState(for: .preparing, appName: "Echo").showRecordingPill)
        XCTAssertFalse(statusItemVisualState(for: .pendingFinalize, appName: "Echo").showRecordingPill)
        XCTAssertFalse(statusItemVisualState(for: .finalizing, appName: "Echo").showRecordingPill)
    }

    func testLeavingRecordingRemovesRedPill() {
        let exitStates: [RecorderState] = [.pendingFinalize, .finalizing, .idle]

        for state in exitStates {
            XCTAssertFalse(
                statusItemVisualState(for: state, appName: "Echo").showRecordingPill,
                "Expected no recording pill in state \(state)"
            )
        }
    }

    private func assertVisualState(
        _ visualState: StatusItemVisualState,
        symbolName: String,
        showRecordingPill: Bool,
        usesPaletteColor: Bool,
        accessibilityLabel: String,
        isAnimated: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(visualState.symbolName, symbolName, file: file, line: line)
        XCTAssertEqual(visualState.symbolWeight, .medium, file: file, line: line)
        XCTAssertEqual(visualState.showRecordingPill, showRecordingPill, file: file, line: line)
        XCTAssertEqual(visualState.usesPaletteColor, usesPaletteColor, file: file, line: line)
        XCTAssertEqual(visualState.accessibilityLabel, accessibilityLabel, file: file, line: line)
        XCTAssertEqual(visualState.isAnimated, isAnimated, file: file, line: line)
    }
}
