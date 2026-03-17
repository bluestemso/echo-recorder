import Combine
import Foundation

@MainActor
final class RecordingViewModel: ObservableObject {
    enum InputSource: CaseIterable, Hashable {
        case system
        case microphone

        var title: String {
            switch self {
            case .system:
                return "System Audio"
            case .microphone:
                return "Microphone"
            }
        }
    }

    struct LevelRow: Equatable {
        let source: InputSource
        let title: String
        let level: SourceLevel
    }

    @Published private(set) var levelRows: [LevelRow] = InputSource.allCases.map { source in
        LevelRow(source: source, title: source.title, level: .zero)
    }
    @Published private(set) var isRecording = false

    var primaryActionTitle: String {
        isRecording ? "Stop Recording" : "Start Recording"
    }

    private let onStartRecording: () -> Void
    private let onStopRecording: () -> Void
    private weak var recorderCoordinator: RecorderCoordinator?
    private var cancellables: Set<AnyCancellable> = []

    init(
        recorderCoordinator: RecorderCoordinator? = nil,
        onStartRecording: @escaping () -> Void = {},
        onStopRecording: @escaping () -> Void = {}
    ) {
        self.recorderCoordinator = recorderCoordinator
        self.onStartRecording = onStartRecording
        self.onStopRecording = onStopRecording

        recorderCoordinator?.$state
            .sink { [weak self] state in
                self?.bindRecorderState(state)
            }
            .store(in: &cancellables)

        if let recorderState = recorderCoordinator?.state {
            bindRecorderState(recorderState)
        }
    }

    func updateLevels(_ levels: [InputSource: SourceLevel]) {
        levelRows = InputSource.allCases.map { source in
            LevelRow(source: source, title: source.title, level: levels[source] ?? .zero)
        }
    }

    func bindRecorderState(_ state: RecorderState) {
        isRecording = state == .preparing || state == .recording
    }

    func toggleRecording() {
        if isRecording {
            if let recorderCoordinator {
                recorderCoordinator.stopRecording()
            } else {
                onStopRecording()
            }
        } else {
            if let recorderCoordinator {
                recorderCoordinator.startRecording()
            } else {
                onStartRecording()
            }
        }
    }
}
