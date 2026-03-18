import AVFoundation
import CoreAudio

enum MicCaptureServiceError: Error, Equatable {
    case alreadyCapturing
    case notCapturing
}

protocol MicCaptureEngine: AnyObject {
    func installTap(_ handler: @escaping (MicSampleBuffer) -> Void)
    func removeTap()
    func start() throws
    func stop()
    var selectedDeviceID: String? { get set }
    func selectDevice(_ device: AudioInputDevice)
}

protocol MicCaptureServicing {
    var isCapturing: Bool { get }
    var onMicSamples: ((MicSampleBuffer) -> Void)? { get set }

    func startCapture() throws
    func stopCapture() throws
    func selectDevice(_ device: AudioInputDevice)
}

final class MicCaptureService: MicCaptureServicing {
    var onMicSamples: ((MicSampleBuffer) -> Void)?

    private let engine: any MicCaptureEngine

    private(set) var isCapturing = false

    func selectDevice(_ device: AudioInputDevice) {
        engine.selectedDeviceID = device.uid
    }

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
    var selectedDeviceID: String?

    private var originalDefaultInputDevice: AudioObjectID = kAudioObjectUnknown

    init(audioEngine: AVAudioEngine = AVAudioEngine()) {
        self.audioEngine = audioEngine
    }

    func selectDevice(_ device: AudioInputDevice) {
        selectedDeviceID = device.uid
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
        // Apply device selection before starting engine
        if let uid = selectedDeviceID, !uid.isEmpty, uid != "default" {
            setInputDevice(deviceUID: uid)
        }
        try audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
        restoreOriginalDefaultInputDevice()
    }

    private func setInputDevice(deviceUID: String) {
        guard let deviceID = resolveDeviceID(from: deviceUID) else {
            print("[CaptureDebug] Could not resolve device UID: \(deviceUID)")
            return
        }
        // Store current default so we can restore it
        originalDefaultInputDevice = getDefaultInputDevice()

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var newDevice = deviceID
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioObjectID>.size),
            &newDevice
        )
        if status == noErr {
            print("[CaptureDebug] Set default input device to UID: \(deviceUID)")
        } else {
            print("[CaptureDebug] Failed to set default input device, status: \(status)")
        }
    }

    private func restoreOriginalDefaultInputDevice() {
        guard originalDefaultInputDevice != kAudioObjectUnknown else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = originalDefaultInputDevice
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioObjectID>.size),
            &deviceID
        )
        originalDefaultInputDevice = kAudioObjectUnknown
    }

    private func getDefaultInputDevice() -> AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioObjectID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return deviceID
    }

    private func resolveDeviceID(from uid: String) -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var uidRef = uid as CFString
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }
}
