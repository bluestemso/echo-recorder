import AppKit

struct StatusItemVisualState: Equatable {
    let symbolName: String
    let symbolWeight: NSFont.Weight
    let showRecordingPill: Bool
    let usesPaletteColor: Bool
    let accessibilityLabel: String
    let isAnimated: Bool
}

func statusItemVisualState(for state: RecorderState, appName: String) -> StatusItemVisualState {
    switch state {
    case .idle:
        return StatusItemVisualState(
            symbolName: "recordingtape",
            symbolWeight: .medium,
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "\(appName) idle",
            isAnimated: false
        )
    case .preparing:
        return StatusItemVisualState(
            symbolName: "recordingtape",
            symbolWeight: .medium,
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "\(appName) preparing",
            isAnimated: true
        )
    case .recording:
        return StatusItemVisualState(
            symbolName: "record.circle.fill",
            symbolWeight: .medium,
            showRecordingPill: true,
            usesPaletteColor: true,
            accessibilityLabel: "\(appName) recording",
            isAnimated: true
        )
    case .pendingFinalize:
        return StatusItemVisualState(
            symbolName: "recordingtape",
            symbolWeight: .medium,
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "\(appName) pending finalize",
            isAnimated: false
        )
    case .finalizing:
        return StatusItemVisualState(
            symbolName: "externaldrive.badge.checkmark",
            symbolWeight: .medium,
            showRecordingPill: false,
            usesPaletteColor: false,
            accessibilityLabel: "\(appName) finalizing",
            isAnimated: true
        )
    }
}
