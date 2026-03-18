import AVFoundation
import Combine
import Foundation

enum RecorderCoordinatorError: Error {
    case microphonePermissionDenied
    case screenRecordingPermissionDenied
}

@MainActor
final class RecorderCoordinator: ObservableObject {
    @Published
    private(set) var state: RecorderState

    var onMeterSnapshot: ((SourceLevel, SourceLevel) -> Void)?

    private var capture: any CaptureServicing
    private var mic: any MicCaptureServicing
    private let finalizer: any RecordingFinalizing
    private let permissionManager: any PermissionManaging
    private let recordingBufferStore = RecordingBufferStore()
    private var latestSystemMeterLevel: SourceLevel = .zero
    private var latestMicMeterLevel: SourceLevel = .zero
    private let meteringService = MeteringService()
    private var systemGain: Float = 1.0
    private var micGain: Float = 1.0
    private let audioMixer: any AudioMixing
    private let inputDeviceService: AudioInputDeviceService?

    init(
        initialState: RecorderState = .idle,
        capture: (any CaptureServicing)? = nil,
        mic: (any MicCaptureServicing)? = nil,
        finalizer: (any RecordingFinalizing)? = nil,
        permissionManager: (any PermissionManaging)? = nil,
        audioMixer: (any AudioMixing)? = nil,
        inputDeviceService: AudioInputDeviceService? = nil
    ) {
        state = initialState
        self.capture = capture ?? CaptureService()
        self.mic = mic ?? MicCaptureService()
        self.finalizer = finalizer ?? RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: FileManager.default.temporaryDirectory
        )
        self.permissionManager = permissionManager ?? PermissionManager()
        self.audioMixer = audioMixer ?? AudioMixerService()
        self.inputDeviceService = inputDeviceService
    }

    func setGain(_ gain: Float, forSystem: Bool) {
        if forSystem {
            systemGain = gain
        } else {
            micGain = gain
        }
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

    func selectDevice(_ device: AudioInputDevice) {
        mic.selectDevice(device)
    }

    func startAudioRecording(profile: Profile) async throws {
        transition(to: .preparing)

        do {
            try await requestPermissions(for: profile)
            recordingBufferStore.reset()

            // Select input device before starting capture
            if let service = inputDeviceService {
                let device = service.selectedDevice
                mic.selectDevice(device)
#if DEBUG
                print("[CaptureDebug] Selected input device: \(device.name) (uid=\(device.uid))")
#endif
            }

            capture.onSystemAudioSamples = { [weak self] sampleBuffer in
                guard let self else { return }
                let gainedSamples = sampleBuffer.samples.map { $0 * self.systemGain }
                let gainedBuffer = SystemAudioSampleBuffer(
                    samples: gainedSamples,
                    sampleRate: sampleBuffer.sampleRate,
                    channelCount: sampleBuffer.channelCount
                )
                self.recordingBufferStore.appendSystem(gainedBuffer)
                let level = self.meteringService.computeLevel(samples: gainedSamples)
                DispatchQueue.main.async {
                    self.latestSystemMeterLevel = level
                    self.emitMeterSnapshot()
                }
            }
            mic.onMicSamples = { [weak self] sampleBuffer in
                guard let self else { return }
                let gainedSamples = sampleBuffer.samples.map { $0 * self.micGain }
                let gainedBuffer = MicSampleBuffer(
                    samples: gainedSamples,
                    sampleRate: sampleBuffer.sampleRate,
                    channelCount: sampleBuffer.channelCount
                )
                self.recordingBufferStore.appendMic(gainedBuffer)
                let level = self.meteringService.computeLevel(samples: gainedSamples)
                DispatchQueue.main.async {
                    self.latestMicMeterLevel = level
                    self.emitMeterSnapshot()
                }
            }

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

            capture.onSystemAudioSamples = nil
            mic.onMicSamples = nil

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

            capture.onSystemAudioSamples = nil
            mic.onMicSamples = nil
            latestSystemMeterLevel = .zero
            latestMicMeterLevel = .zero
            onMeterSnapshot?(.zero, .zero)

            let recordingData = recordingBufferStore.snapshot()
#if DEBUG
            print("[CaptureDebug] Finalize snapshot systemSamples=\(recordingData.system.samples.count) micSamples=\(recordingData.mic.samples.count) systemRate=\(recordingData.system.sampleRate) micRate=\(recordingData.mic.sampleRate)")
#endif
            let output = try finalizer.finalize(
                fileName: recordingName,
                overrideDirectory: overrideDirectory,
                recordingData: recordingData
            )
            transition(to: .idle)
            return output
        } catch {
            capture.onSystemAudioSamples = nil
            mic.onMicSamples = nil
            latestSystemMeterLevel = .zero
            latestMicMeterLevel = .zero
            onMeterSnapshot?(.zero, .zero)
            transition(to: .idle)
            throw error
        }
    }

    func stopCapture() async throws {
        transition(to: .pendingFinalize)
        if mic.isCapturing {
            try mic.stopCapture()
        }
        if capture.isRunning {
            try await capture.stopCapture()
        }
        capture.onSystemAudioSamples = nil
        mic.onMicSamples = nil
        latestSystemMeterLevel = .zero
        latestMicMeterLevel = .zero
        onMeterSnapshot?(.zero, .zero)
    }

    func finalizeRecording(recordingName: String, overrideDirectory: URL) async throws -> FinalizedAudioOutput {
        transition(to: .finalizing)
        do {
            let recordingData = recordingBufferStore.snapshot()
            let output = try finalizer.finalize(
                fileName: recordingName,
                overrideDirectory: overrideDirectory,
                recordingData: recordingData
            )
            transition(to: .idle)
            return output
        } catch {
            transition(to: .idle)
            throw error
        }
    }

    private func requestPermissions(for profile: Profile) async throws {
        let micStatus = permissionManager.status(for: .microphone)
        if micStatus != .authorized {
            let requestStatus = await permissionManager.request(.microphone)
            guard requestStatus == .authorized else {
                throw RecorderCoordinatorError.microphonePermissionDenied
            }
        }

        if profile.includeSystemAudio {
            let systemStatus = permissionManager.status(for: .screenRecording)
            if systemStatus != .authorized {
                let requestStatus = await permissionManager.request(.screenRecording)
                guard requestStatus == .authorized else {
                    throw RecorderCoordinatorError.screenRecordingPermissionDenied
                }
            }
        }
    }

    private func emitMeterSnapshot() {
        onMeterSnapshot?(latestSystemMeterLevel, latestMicMeterLevel)
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
        case (.recording, .pendingFinalize):
            return true
        case (.pendingFinalize, .finalizing):
            return true
        case (.pendingFinalize, .idle):
            return true
        default:
            return false
        }
    }
}

private final class RecordingBufferStore {
    private let lock = NSLock()

    private var systemSamples: [Float] = []
    private var micSamples: [Float] = []
    private var systemSampleRate: Double = 48_000
    private var micSampleRate: Double = 48_000
    private var systemChannelCount = 1
    private var micChannelCount = 1

    func reset() {
        lock.lock()
        defer { lock.unlock() }

        systemSamples.removeAll(keepingCapacity: true)
        micSamples.removeAll(keepingCapacity: true)
        systemSampleRate = 48_000
        micSampleRate = 48_000
        systemChannelCount = 1
        micChannelCount = 1
    }

    func appendSystem(_ buffer: SystemAudioSampleBuffer) {
        lock.lock()
        defer { lock.unlock() }

        systemSamples.append(contentsOf: buffer.samples)
        systemSampleRate = buffer.sampleRate
        systemChannelCount = max(buffer.channelCount, 1)
    }

    func appendMic(_ buffer: MicSampleBuffer) {
        lock.lock()
        defer { lock.unlock() }

        micSamples.append(contentsOf: buffer.samples)
        micSampleRate = buffer.sampleRate
        micChannelCount = max(buffer.channelCount, 1)
    }

    func snapshot() -> RecordingAudioData {
        lock.lock()
        defer { lock.unlock() }

        return RecordingAudioData(
            system: SystemAudioSampleBuffer(
                samples: systemSamples,
                sampleRate: systemSampleRate,
                channelCount: systemChannelCount
            ),
            mic: MicSampleBuffer(
                samples: micSamples,
                sampleRate: micSampleRate,
                channelCount: micChannelCount
            )
        )
    }
}
