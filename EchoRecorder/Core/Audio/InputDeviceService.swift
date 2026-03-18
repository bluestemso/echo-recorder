import AVFoundation
import CoreAudio
import Foundation

enum DeviceType: String, Codable {
    case builtIn
    case usb
    case bluetooth
    case other
}

struct AudioInputDevice: Identifiable, Equatable, Codable {
    let uid: String
    let name: String
    let deviceType: DeviceType

    var id: String { uid }
}

final class AudioInputDeviceService {
    private let store: JSONStore
    private static let key = "selectedInputDevice"

    init(store: JSONStore) {
        self.store = store
    }

    var availableDevices: [AudioInputDevice] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        guard status == noErr else { return [] }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        guard status == noErr else { return [] }

        return deviceIDs.compactMap { deviceID -> AudioInputDevice? in
            guard hasInputChannels(deviceID: deviceID) else { return nil }

            guard let uid = getDeviceUID(deviceID: deviceID) else { return nil }
            guard let name = getDeviceName(deviceID: deviceID) else { return nil }
            let type = getDeviceType(deviceID: deviceID)

            return AudioInputDevice(uid: uid, name: name, deviceType: type)
        }
    }

    var builtInMicrophone: AudioInputDevice? {
        availableDevices.first { device in
            let name = device.name.lowercased()
            return name.contains("built-in") || name.contains("macbook") || name.contains("internal microphone")
        }
    }

    var defaultDevice: AudioInputDevice {
        builtInMicrophone ?? availableDevices.first ?? AudioInputDevice(uid: "default", name: "Default Input", deviceType: .builtIn)
    }

    var selectedDevice: AudioInputDevice {
        guard let savedUID = try? store.load(String.self, from: Self.key),
              !savedUID.isEmpty,
              savedUID != "default"
        else {
            return defaultDevice
        }
        let available = availableDevices
        if available.contains(where: { $0.uid == savedUID }) {
            return available.first(where: { $0.uid == savedUID })!
        }
        // Saved device unavailable — fall back to default
        return defaultDevice
    }

    func selectDevice(_ device: AudioInputDevice) {
        try? store.save(device.uid, as: Self.key)
    }

    // MARK: - Core Audio Helpers

    private func hasInputChannels(deviceID: AudioObjectID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return false }

        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferListPointer.deallocate() }

        let result = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, bufferListPointer)
        guard result == noErr else { return false }

        let bufferList = bufferListPointer.pointee
        return bufferList.mNumberBuffers > 0
    }

    private func getDeviceUID(deviceID: AudioObjectID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &uid)
        guard status == noErr else { return nil }
        return uid as String
    }

    private func getDeviceName(deviceID: AudioObjectID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &name)
        guard status == noErr else { return nil }
        return name as String
    }

    private func getDeviceType(deviceID: AudioObjectID) -> DeviceType {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var transportType: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &transportType)
        guard status == noErr else { return .other }

        switch transportType {
        case kAudioDeviceTransportTypeUSB: return .usb
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return .bluetooth
        case kAudioDeviceTransportTypeBuiltIn: return .builtIn
        default: return .other
        }
    }
}
