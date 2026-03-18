import SwiftUI

struct RecordingPopoverView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @State private var isShowingInputSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            // Inline settings section - only visible when idle (not recording)
            if !viewModel.availableInputDevices.isEmpty && !viewModel.isRecording {
                settingsSection
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

            if let finalizeVM = viewModel.pendingFinalize,
               let recordingName = viewModel.activeRecordingName {
                FinalizeView(
                    viewModel: finalizeVM,
                    recordingName: recordingName,
                    onSave: { viewModel.confirmFinalize() }
                )
            }
        }
        .padding(12)
        .frame(width: 240)
    }

    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isShowingInputSettings.toggle()
                }
            } label: {
                HStack {
                    Text("Input Settings")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isShowingInputSettings ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .focusable(false)

            if isShowingInputSettings {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Device")
                        .font(.caption)
                        .foregroundStyle(.secondary)

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
                .padding(.leading, 4)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
}
