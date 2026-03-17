import Combine
import Foundation

@MainActor
final class FinalizeRecordingViewModel: ObservableObject {
    @Published private(set) var finalizedURL: URL?

    private let finalizer: RecordingFinalizer

    init(finalizer: RecordingFinalizer) {
        self.finalizer = finalizer
    }

    func finalizeRecording(fileName: String, overrideDirectory: URL?) throws {
        finalizedURL = try finalizer.finalize(fileName: fileName, overrideDirectory: overrideDirectory)
    }
}
