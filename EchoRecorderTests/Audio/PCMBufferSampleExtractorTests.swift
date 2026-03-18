import AVFoundation
import XCTest
@testable import EchoRecorder

final class PCMBufferSampleExtractorTests: XCTestCase {
    func testExtractInterleavedFloatSamplesSupportsInt16PCM() throws {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 48_000,
            channels: 1,
            interleaved: false
        ) else {
            XCTFail("Failed to create Int16 audio format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4) else {
            XCTFail("Failed to create Int16 PCM buffer")
            return
        }

        buffer.frameLength = 4
        guard let channelData = buffer.int16ChannelData else {
            XCTFail("Expected Int16 channel data")
            return
        }

        channelData[0][0] = Int16.max
        channelData[0][1] = 0
        channelData[0][2] = Int16.min
        channelData[0][3] = Int16(Int16.max / 2)

        let samples = PCMBufferSampleExtractor.extractInterleavedFloatSamples(from: buffer)

        XCTAssertEqual(samples.count, 4)
        XCTAssertGreaterThan(samples[0], 0.99)
        XCTAssertEqual(samples[1], 0, accuracy: 0.001)
        XCTAssertLessThan(samples[2], -0.99)
        XCTAssertGreaterThan(samples[3], 0.49)
    }

    func testExtractInterleavedFloatSamplesSupportsInterleavedInt16PCM() throws {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 48_000,
            channels: 2,
            interleaved: true
        ) else {
            XCTFail("Failed to create interleaved Int16 audio format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2) else {
            XCTFail("Failed to create interleaved Int16 PCM buffer")
            return
        }

        buffer.frameLength = 2
        let audioBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        guard let data = audioBuffers[0].mData?.assumingMemoryBound(to: Int16.self) else {
            XCTFail("Expected interleaved Int16 mData")
            return
        }

        data[0] = Int16.max
        data[1] = Int16.min
        data[2] = Int16(Int16.max / 2)
        data[3] = Int16(Int16.min / 2)

        let samples = PCMBufferSampleExtractor.extractInterleavedFloatSamples(from: buffer)

        XCTAssertEqual(samples.count, 4)
        XCTAssertGreaterThan(samples[0], 0.99)
        XCTAssertLessThan(samples[1], -0.99)
        XCTAssertGreaterThan(samples[2], 0.49)
        XCTAssertLessThan(samples[3], -0.49)
    }
}
