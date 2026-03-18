import SwiftUI

struct RecordingPopoverView: View {
    @ObservedObject var viewModel: RecordingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(12)
        .frame(width: 240)
    }
}
