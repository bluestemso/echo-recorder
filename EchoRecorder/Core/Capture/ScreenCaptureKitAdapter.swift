import Foundation
import AudioToolbox
import CoreMedia
import ScreenCaptureKit

@MainActor
protocol ScreenCaptureKitAdapting: AnyObject {
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)? { get set }

    func startCapture(source: CaptureSourceDescriptor) async throws
    func stopCapture() async throws
}

enum ScreenCaptureKitAdapterError: Error {
    case unsupportedSource
    case noDisplayAvailable
    case audioBufferExtractionFailed(OSStatus)
}

@MainActor
final class ScreenCaptureKitAdapter: NSObject, ScreenCaptureKitAdapting {
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)?

    private var stream: SCStream?
    private let sampleQueue: DispatchQueue
    private var didLogFirstSystemSample = false

    init(sampleQueue: DispatchQueue = DispatchQueue(label: "echo.recorder.system-audio")) {
        self.sampleQueue = sampleQueue
    }

    func startCapture(source: CaptureSourceDescriptor) async throws {
        guard case .systemAudio = source else {
            throw ScreenCaptureKitAdapterError.unsupportedSource
        }

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw ScreenCaptureKitAdapterError.noDisplayAvailable
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = false
        configuration.sampleRate = 48_000
        configuration.channelCount = 1

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue)
        try await stream.startCapture()
        self.stream = stream
    }

    func stopCapture() async throws {
        guard let stream else {
            return
        }

        try await stream.stopCapture()
        self.stream = nil
    }

    nonisolated private func parseSystemAudioSampleBuffer(from sampleBuffer: CMSampleBuffer) throws -> SystemAudioSampleBuffer {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbdPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        else {
            throw ScreenCaptureKitAdapterError.audioBufferExtractionFailed(-1)
        }

        let asbd = asbdPointer.pointee
        let sampleRate = asbd.mSampleRate
        let channelCount = Int(max(asbd.mChannelsPerFrame, 1))
        let bitsPerChannel = Int(asbd.mBitsPerChannel)
        let formatFlags = asbd.mFormatFlags
        let isFloat = (formatFlags & kAudioFormatFlagIsFloat) != 0
        let isSignedInteger = (formatFlags & kAudioFormatFlagIsSignedInteger) != 0
        let isNonInterleaved = (formatFlags & kAudioFormatFlagIsNonInterleaved) != 0

        var bufferListSizeNeeded = 0
        _ = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: &bufferListSizeNeeded,
            bufferListOut: nil,
            bufferListSize: 0,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: nil
        )

        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: bufferListSizeNeeded,
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer {
            rawPointer.deallocate()
        }

        let audioBufferListPointer = rawPointer.assumingMemoryBound(to: AudioBufferList.self)
        var blockBuffer: CMBlockBuffer?
        let extractionStatus = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: audioBufferListPointer,
            bufferListSize: bufferListSizeNeeded,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )

        guard extractionStatus == noErr else {
            throw ScreenCaptureKitAdapterError.audioBufferExtractionFailed(extractionStatus)
        }

        let audioBuffers = UnsafeMutableAudioBufferListPointer(audioBufferListPointer)
        let samples = extractSamples(
            from: audioBuffers,
            channelCount: channelCount,
            bitsPerChannel: bitsPerChannel,
            isFloat: isFloat,
            isSignedInteger: isSignedInteger,
            isNonInterleaved: isNonInterleaved
        )

        return SystemAudioSampleBuffer(samples: samples, sampleRate: sampleRate, channelCount: channelCount)
    }

    nonisolated private func extractSamples(
        from audioBuffers: UnsafeMutableAudioBufferListPointer,
        channelCount: Int,
        bitsPerChannel: Int,
        isFloat: Bool,
        isSignedInteger: Bool,
        isNonInterleaved: Bool
    ) -> [Float] {
        guard let firstBuffer = audioBuffers.first,
              let firstData = firstBuffer.mData
        else {
            return []
        }

        let bytesPerSample = max(bitsPerChannel / 8, 1)

        func decodeSample(_ rawPointer: UnsafeRawPointer) -> Float {
            if isFloat && bitsPerChannel == 32 {
                return rawPointer.assumingMemoryBound(to: Float.self).pointee
            }

            if isSignedInteger && bitsPerChannel == 16 {
                return Float(rawPointer.assumingMemoryBound(to: Int16.self).pointee) / Float(Int16.max)
            }

            if isSignedInteger && bitsPerChannel == 32 {
                return Float(rawPointer.assumingMemoryBound(to: Int32.self).pointee) / Float(Int32.max)
            }

            return 0
        }

        if !isNonInterleaved {
            let sampleCount = Int(firstBuffer.mDataByteSize) / bytesPerSample
            var samples: [Float] = []
            samples.reserveCapacity(sampleCount)

            for index in 0..<sampleCount {
                let samplePointer = firstData.advanced(by: index * bytesPerSample)
                samples.append(decodeSample(UnsafeRawPointer(samplePointer)))
            }

            return samples
        }

        guard audioBuffers.count >= channelCount else {
            return []
        }

        let frames = Int(firstBuffer.mDataByteSize) / bytesPerSample
        var samples: [Float] = []
        samples.reserveCapacity(frames * channelCount)

        for frame in 0..<frames {
            for channel in 0..<channelCount {
                let buffer = audioBuffers[channel]
                guard let channelData = buffer.mData else {
                    samples.append(0)
                    continue
                }

                let samplePointer = channelData.advanced(by: frame * bytesPerSample)
                samples.append(decodeSample(UnsafeRawPointer(samplePointer)))
            }
        }

        return samples
    }
}

extension ScreenCaptureKitAdapter: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .audio else {
            return
        }

        guard let parsedBuffer = try? parseSystemAudioSampleBuffer(from: sampleBuffer) else {
            return
        }

        Task { @MainActor in
            if !didLogFirstSystemSample {
                didLogFirstSystemSample = true
                print("[CaptureDebug] System audio received first sample chunk count=\(parsedBuffer.samples.count) sampleRate=\(parsedBuffer.sampleRate) channels=\(parsedBuffer.channelCount)")
            }
            onSystemAudioSamples?(parsedBuffer)
        }
    }
}

extension ScreenCaptureKitAdapter: SCStreamDelegate {}
