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

    init(audioEngine: AVAudioEngine = AVAudioEngine()) {
        self.audioEngine = audioEngine
    }

    func installTap(_ handler: @escaping (MicSampleBuffer) -> Void) {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { buffer, _ in
            guard let channelData = buffer.floatChannelData else {
                return
            }

            let frameLength = Int(buffer.frameLength)
            let channelCount = Int(buffer.format.channelCount)
            var samples: [Float] = []
            samples.reserveCapacity(frameLength * max(channelCount, 1))

            for frame in 0..<frameLength {
                for channel in 0..<channelCount {
                    samples.append(channelData[channel][frame])
                }
            }

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
