import Combine

@MainActor
final class RecorderCoordinator: ObservableObject {
    @Published
    private(set) var state: RecorderState

    init(initialState: RecorderState = .idle) {
        state = initialState
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
        case (.preparing, .idle):
            return true
        case (.recording, .idle):
            return true
        default:
            return false
        }
    }
}
