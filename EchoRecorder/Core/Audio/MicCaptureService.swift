import AVFoundation

enum MicCaptureServiceError: Error, Equatable {
    case alreadyCapturing
    case notCapturing
}

protocol MicCaptureEngine: AnyObject {
    func installTap(_ handler: @escaping (MicSampleBuffer) -> Void)
    func removeTap()
    func start() throws
    func stop()
}

protocol MicCaptureServicing {
    var isCapturing: Bool { get }
    var onMicSamples: ((MicSampleBuffer) -> Void)? { get set }

    func startCapture() throws
    func stopCapture() throws
}

final class MicCaptureService: MicCaptureServicing {
    var onMicSamples: ((MicSampleBuffer) -> Void)?

    private let engine: any MicCaptureEngine

    private(set) var isCapturing = false

    init(engine: any MicCaptureEngine = AVAudioEngineAdapter()) {
        self.engine = engine
    }

    func startCapture() throws {
        guard !isCapturing else {
            throw MicCaptureServiceError.alreadyCapturing
        }

        engine.installTap { [weak self] sampleBuffer in
            self?.onMicSamples?(sampleBuffer)
        }

        do {
            try engine.start()
            isCapturing = true
        } catch {
            engine.removeTap()
            throw error
        }
    }

    func stopCapture() throws {
        guard isCapturing else {
            throw MicCaptureServiceError.notCapturing
        }

        engine.removeTap()
        engine.stop()
        isCapturing = false
    }
}

final class AVAudioEngineAdapter: MicCaptureEngine {
    private let audioEngine: AVAudioEngine
    private var didLogFirstTapSample = false

    init(audioEngine: AVAudioEngine = AVAudioEngine()) {
        self.audioEngine = audioEngine
    }

    func installTap(_ handler: @escaping (MicSampleBuffer) -> Void) {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

#if DEBUG
        print("[CaptureDebug] Mic tap format sampleRate=\(inputFormat.sampleRate) channels=\(inputFormat.channelCount) commonFormat=\(inputFormat.commonFormat.rawValue) interleaved=\(inputFormat.isInterleaved)")
#endif

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { buffer, _ in
            let samples = PCMBufferSampleExtractor.extractInterleavedFloatSamples(from: buffer)
            guard !samples.isEmpty else {
                return
            }

#if DEBUG
            if !self.didLogFirstTapSample {
                self.didLogFirstTapSample = true
                print("[CaptureDebug] Mic tap received first sample chunk count=\(samples.count) sampleRate=\(buffer.format.sampleRate) channels=\(buffer.format.channelCount)")
            }
#endif

            let channelCount = Int(buffer.format.channelCount)

            handler(
                MicSampleBuffer(
                    samples: samples,
                    sampleRate: buffer.format.sampleRate,
                    channelCount: channelCount
                )
            )
        }
    }

    func removeTap() {
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    func start() throws {
        try audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
    }
}
