enum CaptureServiceError: Error, Equatable {
    case alreadyRunning
    case notRunning
}

@MainActor
protocol CaptureServicing {
    var isRunning: Bool { get }
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)? { get set }

    func startCapture(source: CaptureSourceDescriptor) async throws
    func stopCapture() async throws
}

@MainActor
final class CaptureService: CaptureServicing {
    private enum LifecycleState {
        case idle
        case starting
        case running
        case stopping
    }

    private let adapter: any ScreenCaptureKitAdapting

    private var lifecycleState: LifecycleState = .idle

    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)? {
        didSet {
            guard onSystemAudioSamples != nil else {
                adapter.onSystemAudioSamples = nil
                return
            }

            adapter.onSystemAudioSamples = { [weak self] sampleBuffer in
                self?.onSystemAudioSamples?(sampleBuffer)
            }
        }
    }

    var isRunning: Bool {
        lifecycleState == .running || lifecycleState == .stopping
    }

    init(adapter: any ScreenCaptureKitAdapting) {
        self.adapter = adapter
    }

    convenience init() {
        self.init(adapter: ScreenCaptureKitAdapter())
    }

    func startCapture(source: CaptureSourceDescriptor) async throws {
        guard lifecycleState == .idle else {
            throw CaptureServiceError.alreadyRunning
        }

        lifecycleState = .starting

        do {
            try await adapter.startCapture(source: source)
            lifecycleState = .running
        } catch {
            lifecycleState = .idle
            throw error
        }
    }

    func stopCapture() async throws {
        guard lifecycleState == .running else {
            throw CaptureServiceError.notRunning
        }

        lifecycleState = .stopping

        do {
            try await adapter.stopCapture()
            lifecycleState = .idle
        } catch {
            lifecycleState = .running
            throw error
        }
    }
}
