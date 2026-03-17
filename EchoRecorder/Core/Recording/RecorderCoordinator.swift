import Combine
import Foundation

@MainActor
final class RecorderCoordinator: ObservableObject {
    @Published
    private(set) var state: RecorderState

    private let capture: any CaptureServicing
    private let mic: any MicCaptureServicing
    private let finalizer: any RecordingFinalizing

    init(
        initialState: RecorderState = .idle,
        capture: (any CaptureServicing)? = nil,
        mic: (any MicCaptureServicing)? = nil,
        finalizer: (any RecordingFinalizing)? = nil
    ) {
        state = initialState
        self.capture = capture ?? CaptureService()
        self.mic = mic ?? MicCaptureService()
        self.finalizer = finalizer ?? RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: FileManager.default.temporaryDirectory
        )
    }

    func startRecording() {
        transition(to: .preparing)
    }

    func markRecordingStarted() {
        transition(to: .recording)
    }

    func stopRecording() {
        transition(to: .idle)
    }

    func startAudioRecording(profile: Profile) async throws {
        transition(to: .preparing)

        do {
            if profile.includeSystemAudio {
                try await capture.startCapture(source: .systemAudio)
            }

            if profile.micDeviceID != nil {
                try mic.startCapture()
            }

            transition(to: .recording)
        } catch {
            if mic.isCapturing {
                try? mic.stopCapture()
            }

            if capture.isRunning {
                try? await capture.stopCapture()
            }

            transition(to: .idle)
            throw error
        }
    }

    func stopAndFinalize(recordingName: String, overrideDirectory: URL?) async throws -> FinalizedAudioOutput {
        transition(to: .finalizing)

        do {
            if mic.isCapturing {
                try mic.stopCapture()
            }

            if capture.isRunning {
                try await capture.stopCapture()
            }

            let output = try finalizer.finalize(fileName: recordingName, overrideDirectory: overrideDirectory)
            transition(to: .idle)
            return output
        } catch {
            transition(to: .idle)
            throw error
        }
    }

    private func transition(to nextState: RecorderState) {
        guard canTransition(from: state, to: nextState) else {
            return
        }

        state = nextState
    }

    private func canTransition(from currentState: RecorderState, to nextState: RecorderState) -> Bool {
        switch (currentState, nextState) {
        case (.idle, .preparing):
            return true
        case (.preparing, .recording):
            return true
        case (.recording, .finalizing):
            return true
        case (.preparing, .idle):
            return true
        case (.finalizing, .idle):
            return true
        case (.recording, .idle):
            return true
        default:
            return false
        }
    }
}
