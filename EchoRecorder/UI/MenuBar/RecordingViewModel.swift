import AVFoundation
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
    @Published private(set) var pendingFinalize: FinalizeRecordingViewModel?

    // MARK: - Input Device Selection
    @Published private(set) var selectedDevice: AudioInputDevice
    @Published private(set) var availableInputDevices: [AudioInputDevice] = []

    private let inputDeviceService: AudioInputDeviceService

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
    private(set) var activeRecordingName: String?

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
        onStopRecording: @escaping () -> Void = {},
        inputDeviceServiceProvider: @escaping () -> AudioInputDeviceService = {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let store = JSONStore(baseDirectory: appSupport.appendingPathComponent("EchoRecorder", isDirectory: true))
            return AudioInputDeviceService(store: store)
        }
    ) {
        self.recorderCoordinator = recorderCoordinator
        self.audioMixer = audioMixer
        self.profileProvider = profileProvider
        self.outputDirectoryProvider = outputDirectoryProvider
        self.recordingNameProvider = recordingNameProvider
        self.onStartRecording = onStartRecording
        self.onStopRecording = onStopRecording
        self.inputDeviceService = inputDeviceServiceProvider()
        self.selectedDevice = inputDeviceService.selectedDevice
        self.availableInputDevices = inputDeviceService.availableDevices

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

    func setSelectedDevice(_ device: AudioInputDevice) {
        inputDeviceService.selectDevice(device)
        selectedDevice = device
        availableInputDevices = inputDeviceService.availableDevices
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
            pendingFinalize = nil
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
        recorderCoordinator?.setGain(value, forSystem: source == .system)
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

    func confirmFinalize() {
        guard let coordinator = recorderCoordinator,
              let recordingName = activeRecordingName
        else { return }

        Task { [weak self] in
            guard let self, let finalizeVM = self.pendingFinalize else { return }
            do {
                let output = try await coordinator.finalizeRecording(
                    recordingName: recordingName,
                    overrideDirectory: finalizeVM.selectedDirectory
                )
                self.lastFinalizedOutput = output
                self.pendingFinalize = nil
                self.activeRecordingName = nil
#if DEBUG
                print("[CaptureDebug] confirmFinalize mixed=\(output.mixed.path)")
#endif
            } catch {
                self.latestErrorDescription = error.localizedDescription
                self.pendingFinalize = nil
                self.activeRecordingName = nil
            }
        }
    }

    static func makeSaveLocationService() -> SaveLocationService {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let store = JSONStore(baseDirectory: appSupport.appendingPathComponent("EchoRecorder", isDirectory: true))
        return SaveLocationService(store: store)
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
        activeRecordingName = recordingName

        do {
            try await coordinator.stopCapture()
            let finalizer = RecordingFinalizer(
                fileWriter: FileWriterService(),
                defaultDirectory: SaveLocationService.defaultFallback
            )
            pendingFinalize = FinalizeRecordingViewModel(
                finalizer: finalizer,
                saveLocationService: RecordingViewModel.makeSaveLocationService()
            )
#if DEBUG
            print("[CaptureDebug] stopCapture complete, awaiting finalize for name=\(recordingName)")
#endif
        } catch {
            latestErrorDescription = error.localizedDescription
            activeRecordingName = nil
#if DEBUG
            print("[CaptureDebug] stopRecording failed error=\(error)")
#endif
        }
    }
}
