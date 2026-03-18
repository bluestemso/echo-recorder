import Foundation
import AVFoundation

struct FinalizedAudioOutput: Equatable {
    let folder: URL
    let mixed: URL
    let system: URL
    let mic: URL
}

protocol AudioWriterPipelining {
    func writeAudioOutputs(
        recordingName: String,
        in directory: URL,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput
}

extension AudioWriterPipelining {
    func writeAudioOutputs(recordingName: String, in directory: URL) throws -> FinalizedAudioOutput {
        try writeAudioOutputs(recordingName: recordingName, in: directory, recordingData: .empty)
    }
}

struct AudioWriterPipeline: AudioWriterPipelining {
    private let fileManager: FileManager
    private let mixer: any AudioMixing

    init(fileManager: FileManager = .default, mixer: any AudioMixing = AudioMixerService()) {
        self.fileManager = fileManager
        self.mixer = mixer
    }

    func writeAudioOutputs(
        recordingName: String,
        in directory: URL,
        recordingData: RecordingAudioData
    ) throws -> FinalizedAudioOutput {
        let folder = directory.appendingPathComponent(recordingName, isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let output = FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a", isDirectory: false),
            system: folder.appendingPathComponent("system_audio.m4a", isDirectory: false),
            mic: folder.appendingPathComponent("mic_audio.m4a", isDirectory: false)
        )

        try writeTrack(recordingData.system.samples, sampleRate: recordingData.system.sampleRate, channelCount: recordingData.system.channelCount, to: output.system)
        try writeTrack(recordingData.mic.samples, sampleRate: recordingData.mic.sampleRate, channelCount: recordingData.mic.channelCount, to: output.mic)

        let mixedSamples = mixer.mix([recordingData.system.samples, recordingData.mic.samples])
        let mixedSampleRate = recordingData.system.samples.isEmpty ? recordingData.mic.sampleRate : recordingData.system.sampleRate
        let mixedChannelCount = max(recordingData.system.channelCount, recordingData.mic.channelCount)
        try writeTrack(mixedSamples, sampleRate: mixedSampleRate, channelCount: mixedChannelCount, to: output.mixed)

        return output
    }

    private func writeTrack(
        _ samples: [Float],
        sampleRate: Double,
        channelCount: Int,
        to url: URL
    ) throws {
        let resolvedSampleRate = sampleRate > 0 ? sampleRate : 48_000
        let resolvedChannelCount = max(channelCount, 1)
        let sanitized = samples.map { sample -> Float in
            guard sample.isFinite else {
                return 0
            }
            return min(max(sample, -1), 1)
        }
        let safeSamples = sanitized.isEmpty ? Array(repeating: Float.zero, count: resolvedChannelCount) : sanitized
        let frameCount = max(safeSamples.count / resolvedChannelCount, 1)

#if DEBUG
        let minSample = safeSamples.min() ?? 0
        let maxSample = safeSamples.max() ?? 0
        let nonZeroCount = safeSamples.reduce(into: 0) { count, value in
            if value != 0 { count += 1 }
        }
        print("[CaptureDebug] writeTrack path=\(url.lastPathComponent) samples=\(safeSamples.count) frames=\(frameCount) channels=\(resolvedChannelCount) min=\(minSample) max=\(maxSample) nonZero=\(nonZeroCount)")
#endif

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: resolvedSampleRate,
            channels: AVAudioChannelCount(resolvedChannelCount),
            interleaved: false
        ) else {
            throw AudioWriterPipelineError.invalidAudioFormat
        }

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else {
            throw AudioWriterPipelineError.bufferAllocationFailed
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        if let channelData = buffer.floatChannelData {
            for frame in 0..<frameCount {
                for channel in 0..<resolvedChannelCount {
                    let sourceIndex = frame * resolvedChannelCount + channel
                    let sample = sourceIndex < safeSamples.count ? safeSamples[sourceIndex] : Float.zero
                    channelData[channel][frame] = sample
                }
            }
        }

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: resolvedSampleRate,
            AVNumberOfChannelsKey: resolvedChannelCount,
            AVEncoderBitRateKey: 192_000
        ]

        let file = try AVAudioFile(
            forWriting: url,
            settings: settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        try file.write(from: buffer)
    }
}

enum AudioWriterPipelineError: Error {
    case invalidAudioFormat
    case bufferAllocationFailed
}
