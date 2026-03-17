import SwiftUI

struct RecordingPopoverView: View {
    @ObservedObject var viewModel: RecordingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.levelRows, id: \.source) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                    ProgressView(value: Double(row.level.peak), total: 1)
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
