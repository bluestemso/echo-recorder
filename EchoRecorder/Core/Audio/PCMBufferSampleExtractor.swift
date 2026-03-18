import AVFoundation

enum PCMBufferSampleExtractor {
    static func extractInterleavedFloatSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(max(buffer.format.channelCount, 1))

        guard frameLength > 0 else {
            return []
        }

        let audioBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        let isInterleavedLayout = audioBuffers.count == 1 && channelCount > 1

        switch buffer.format.commonFormat {
        case .pcmFormatFloat32:
            if isInterleavedLayout {
                guard let data = audioBuffers[0].mData?.assumingMemoryBound(to: Float.self) else {
                    return []
                }

                let sampleCount = Int(audioBuffers[0].mDataByteSize) / MemoryLayout<Float>.size
                return Array(UnsafeBufferPointer(start: data, count: sampleCount))
            }

            return extractPlanarSamples(
                from: audioBuffers,
                frameLength: frameLength,
                channelCount: channelCount,
                stride: MemoryLayout<Float>.size,
                convert: { rawPointer in
                    Float(rawPointer.assumingMemoryBound(to: Float.self).pointee)
                }
            )

        case .pcmFormatInt16:
            let scale = 1.0 / Float(Int16.max)

            if isInterleavedLayout {
                guard let data = audioBuffers[0].mData?.assumingMemoryBound(to: Int16.self) else {
                    return []
                }

                let sampleCount = Int(audioBuffers[0].mDataByteSize) / MemoryLayout<Int16>.size
                return (0..<sampleCount).map { Float(data[$0]) * scale }
            }

            return extractPlanarSamples(
                from: audioBuffers,
                frameLength: frameLength,
                channelCount: channelCount,
                stride: MemoryLayout<Int16>.size,
                convert: { rawPointer in
                    Float(rawPointer.assumingMemoryBound(to: Int16.self).pointee) * scale
                }
            )

        case .pcmFormatInt32:
            let scale = 1.0 / Float(Int32.max)

            if isInterleavedLayout {
                guard let data = audioBuffers[0].mData?.assumingMemoryBound(to: Int32.self) else {
                    return []
                }

                let sampleCount = Int(audioBuffers[0].mDataByteSize) / MemoryLayout<Int32>.size
                return (0..<sampleCount).map { Float(data[$0]) * scale }
            }

            return extractPlanarSamples(
                from: audioBuffers,
                frameLength: frameLength,
                channelCount: channelCount,
                stride: MemoryLayout<Int32>.size,
                convert: { rawPointer in
                    Float(rawPointer.assumingMemoryBound(to: Int32.self).pointee) * scale
                }
            )

        default:
            return []
        }
    }

    private static func extractPlanarSamples(
        from audioBuffers: UnsafeMutableAudioBufferListPointer,
        frameLength: Int,
        channelCount: Int,
        stride: Int,
        convert: (UnsafeRawPointer) -> Float
    ) -> [Float] {
        guard audioBuffers.count >= channelCount else {
            return []
        }

        var samples: [Float] = []
        samples.reserveCapacity(frameLength * channelCount)

        for frame in 0..<frameLength {
            for channel in 0..<channelCount {
                let audioBuffer = audioBuffers[channel]
                guard let data = audioBuffer.mData else {
                    samples.append(0)
                    continue
                }

                let sampleCount = Int(audioBuffer.mDataByteSize) / stride
                guard frame < sampleCount else {
                    samples.append(0)
                    continue
                }

                let samplePointer = data.advanced(by: frame * stride)
                samples.append(convert(UnsafeRawPointer(samplePointer)))
            }
        }

        return samples
    }
}
