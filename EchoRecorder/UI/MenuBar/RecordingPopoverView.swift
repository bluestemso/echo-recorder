import SwiftUI

struct RecordingPopoverView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var contentTransition: AnyTransition {
        PopoverContentTransitionPolicy
            .resolve(reduceMotion: accessibilityReduceMotion)
            .transition
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let finalizeVM = viewModel.pendingFinalize,
               viewModel.activeRecordingName != nil {
                FinalizeView(
                    viewModel: finalizeVM,
                    recordingName: $viewModel.pendingFinalizeName,
                    finalizeUIState: viewModel.finalizeUIState,
                    onSave: { viewModel.confirmFinalize() }
                )
                .transition(contentTransition)
            } else {
                liveRecordingContent
                    .transition(contentTransition)
            }
        }
        .padding(12)
        .frame(width: 240)
        .animation(
            .easeInOut(duration: PopoverUXTiming.contentTransitionDuration),
            value: viewModel.pendingFinalize != nil
        )
    }

    @ViewBuilder
    private var liveRecordingContent: some View {
        // Error state warning for device issues
        if let error = viewModel.latestErrorDescription,
           viewModel.latestErrorDescription?.lowercased().contains("device") == true ||
            viewModel.latestErrorDescription?.lowercased().contains("input") == true ||
            viewModel.latestErrorDescription?.lowercased().contains("microphone") == true {
            Text(error)
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
        }

        // Input device selector - only visible when idle
        if !viewModel.availableInputDevices.isEmpty && !viewModel.isRecording {
            inputDeviceSection
        }

        ForEach(viewModel.levelRows, id: \.source) { row in
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LevelMeterView(level: row.level)
                HStack(spacing: 6) {
                    Text("Gain")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Slider(
                        value: Binding(
                            get: { viewModel.gainValues[row.source] ?? 1.0 },
                            set: { viewModel.setGain($0, for: row.source) }
                        ),
                        in: 0.0...2.0
                    )
                }
            }
        }

        Button(viewModel.primaryActionTitle) {
            viewModel.toggleRecording()
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private var inputDeviceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input Device")
                .font(.caption)
                .fontWeight(.medium)

            InputDevicePicker(
                selectedDevice: Binding(
                    get: { viewModel.selectedDevice },
                    set: { viewModel.setSelectedDevice($0) }
                ),
                availableDevices: viewModel.availableInputDevices,
                onDeviceSelected: { viewModel.setSelectedDevice($0) },
                isEnabled: !viewModel.isRecording
            )
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
}
