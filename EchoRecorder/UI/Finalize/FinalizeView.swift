import SwiftUI

struct FinalizeView: View {
    @ObservedObject var viewModel: FinalizeRecordingViewModel
    let recordingName: String
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Text("Save Recording")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text(viewModel.displayPath)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Change Location") {
                    viewModel.chooseDirectory()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }

            Button("Save") {
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}
