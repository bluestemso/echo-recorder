import Combine
import Foundation

@MainActor
final class FinalizeRecordingViewModel: ObservableObject {
    @Published private(set) var finalizedOutput: FinalizedAudioOutput?

    var finalizedURL: URL? {
        finalizedOutput?.mixed
    }

    private let finalizer: RecordingFinalizer

    init(finalizer: RecordingFinalizer) {
        self.finalizer = finalizer
    }

    func finalizeRecording(fileName: String, overrideDirectory: URL?) throws {
        finalizedOutput = try finalizer.finalize(fileName: fileName, overrideDirectory: overrideDirectory)
    }
}
