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
    @Published private(set) var lastFinalizedOutput: FinalizedAudioOutput?
    @Published private(set) var latestErrorDescription: String?
    @Published private(set) var gainValues: [InputSource: Float] = [
        .system: 1.0,
        .microphone: 1.0
    ]

    var primaryActionTitle: String {
        isRecording ? "Stop Recording" : "Start Recording"
    }

    private let onStartRecording: () -> Void
    private let onStopRecording: () -> Void
    private let profileProvider: () -> Profile
    private let outputDirectoryProvider: () -> URL?
    private let recordingNameProvider: () -> String
    private let audioMixer: any AudioMixing
    private weak var recorderCoordinator: RecorderCoordinator?
    private var cancellables: Set<AnyCancellable> = []
    private var sourceGain = SourceGain.unity
    private var activeRecordingName: String?

    init(
        recorderCoordinator: RecorderCoordinator? = nil,
        audioMixer: any AudioMixing = AudioMixerService(),
        profileProvider: @escaping () -> Profile = {
            Profile(id: "default", name: "Default")
        },
        outputDirectoryProvider: @escaping () -> URL? = {
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
        },
        recordingNameProvider: @escaping () -> String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            return "Echo-\(formatter.string(from: Date()))"
        },
        onStartRecording: @escaping () -> Void = {},
        onStopRecording: @escaping () -> Void = {}
    ) {
        self.recorderCoordinator = recorderCoordinator
        self.audioMixer = audioMixer
        self.profileProvider = profileProvider
        self.outputDirectoryProvider = outputDirectoryProvider
        self.recordingNameProvider = recordingNameProvider
        self.onStartRecording = onStartRecording
        self.onStopRecording = onStopRecording

        recorderCoordinator?.$state
            .sink { [weak self] state in
                self?.bindRecorderState(state)
            }
            .store(in: &cancellables)

        recorderCoordinator?.onMeterSnapshot = { [weak self] systemLevel, micLevel in
            // Already dispatched to main by RecorderCoordinator
            self?.applyMeterSnapshot(system: systemLevel, mic: micLevel)
        }

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
        isRecording = state == .preparing || state == .recording || state == .finalizing
        if state == .idle {
            levelRows = RecordingViewModel.InputSource.allCases.map { source in
                LevelRow(source: source, title: source.title, level: .zero)
            }
        }
    }

    func setGain(_ value: Float, for source: InputSource) {
        switch source {
        case .system:
            sourceGain.system = value
        case .microphone:
            sourceGain.microphone = value
        }
        gainValues[source] = value
    }

    func applyMeterSnapshot(system: SourceLevel, mic: SourceLevel) {
        let gainedLevels = audioMixer.applyGain(system: system, mic: mic, gain: sourceGain)
        updateLevels([
            .system: gainedLevels.system,
            .microphone: gainedLevels.mic
        ])
    }

    func toggleRecording() {
        if isRecording {
            if let recorderCoordinator {
                Task { [weak self] in
                    await self?.stopRecording(using: recorderCoordinator)
                }
            } else {
                onStopRecording()
            }
        } else {
            if let recorderCoordinator {
                Task { [weak self] in
                    await self?.startRecording(using: recorderCoordinator)
                }
            } else {
                onStartRecording()
            }
        }
    }

    private func startRecording(using coordinator: RecorderCoordinator) async {
        let profile = profileProvider()
        let recordingName = recordingNameProvider()
        activeRecordingName = recordingName

        do {
            try await coordinator.startAudioRecording(profile: profile)
#if DEBUG
            print("[CaptureDebug] startRecording succeeded name=\(recordingName)")
#endif
        } catch {
            latestErrorDescription = error.localizedDescription
            activeRecordingName = nil
#if DEBUG
            print("[CaptureDebug] startRecording failed error=\(error)")
#endif
        }
    }

    private func stopRecording(using coordinator: RecorderCoordinator) async {
        let recordingName = activeRecordingName ?? recordingNameProvider()

        do {
            lastFinalizedOutput = try await coordinator.stopAndFinalize(
                recordingName: recordingName,
                overrideDirectory: outputDirectoryProvider()
            )
            activeRecordingName = nil
#if DEBUG
            if let output = lastFinalizedOutput {
                print("[CaptureDebug] stopRecording finalized mixed=\(output.mixed.path) system=\(output.system.path) mic=\(output.mic.path)")
            }
#endif
        } catch {
            latestErrorDescription = error.localizedDescription
#if DEBUG
            print("[CaptureDebug] stopRecording failed error=\(error)")
#endif
        }
    }
}
