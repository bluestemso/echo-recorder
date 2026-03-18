import Combine
import Foundation
import AppKit

@MainActor
final class FinalizeRecordingViewModel: ObservableObject {
    @Published private(set) var finalizedOutput: FinalizedAudioOutput?
    @Published var selectedDirectory: URL

    var finalizedURL: URL? {
        finalizedOutput?.mixed
    }

    var displayPath: String {
        selectedDirectory.path
    }

    private let finalizer: RecordingFinalizer
    private let saveLocationService: SaveLocationService

    init(finalizer: RecordingFinalizer, saveLocationService: SaveLocationService? = nil) {
        self.finalizer = finalizer
        self.saveLocationService = saveLocationService ?? RecordingViewModel.makeSaveLocationService()
        self.selectedDirectory = self.saveLocationService.load() ?? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
    }

    func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            selectedDirectory = url
            try? saveLocationService.save(url)
        }
    }

    func finalizeRecording(fileName: String, overrideDirectory: URL?) throws {
        finalizedOutput = try finalizer.finalize(fileName: fileName, overrideDirectory: overrideDirectory)
    }
}
