import SwiftUI

struct FinalizeView: View {
    enum Copy {
        static let saveButtonTitle = "Save Recording"
        static let saveProgressTitle = "Saving recording..."
        static let changeLocationTitle = "Change Location"
        static let nameFieldPlaceholder = "Recording name"
    }

    @ObservedObject var viewModel: FinalizeRecordingViewModel
    @Binding var recordingName: String
    let finalizeUIState: RecordingViewModel.FinalizeUIState
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Finalize Recording")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField(Copy.nameFieldPlaceholder, text: $recordingName)
                .textFieldStyle(.roundedBorder)
                .disabled(finalizeUIState != .editing)

            VStack(alignment: .leading, spacing: 4) {
                Text("Save location")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(viewModel.displayPath)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button {
                viewModel.chooseDirectory()
            } label: {
                Label(Copy.changeLocationTitle, systemImage: "folder")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(finalizeUIState == .saving)

            actionContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var actionContent: some View {
        switch finalizeUIState {
        case .editing:
            Button(Copy.saveButtonTitle) {
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
        case .saving:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(Copy.saveProgressTitle)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        case .success:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Recording saved")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.12))
            .cornerRadius(6)
        }
    }
}
