import SwiftUI

// MARK: - Stub Types (replace with imports from InputDeviceService.swift after 04-01 executes)

enum DeviceType: String, Codable {
    case builtIn
    case usb
    case bluetooth
    case other
}

struct AudioInputDevice: Identifiable, Equatable, Codable, Hashable {
    let uid: String
    let name: String
    let deviceType: DeviceType

    var id: String { uid }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
}

// MARK: - Device Type Badge

struct DeviceTypeBadge: View {
    let deviceType: DeviceType

    var body: some View {
        Text(badgeText)
            .font(.caption2)
            .foregroundStyle(badgeColor)
    }

    private var badgeText: String {
        switch deviceType {
        case .builtIn: return "Built-in"
        case .usb: return "USB"
        case .bluetooth: return "Bluetooth"
        case .other: return "Other"
        }
    }

    private var badgeColor: Color {
        switch deviceType {
        case .builtIn: return .secondary
        case .usb: return .blue
        case .bluetooth: return .purple
        case .other: return .secondary
        }
    }
}

// MARK: - Input Device Picker

struct InputDevicePicker: View {
    @Binding var selectedDevice: AudioInputDevice
    let availableDevices: [AudioInputDevice]
    let onDeviceSelected: (AudioInputDevice) -> Void
    let isEnabled: Bool

    var body: some View {
        Picker("Input Device", selection: $selectedDevice) {
            ForEach(availableDevices) { device in
                HStack {
                    Text(device.name)
                    DeviceTypeBadge(deviceType: device.deviceType)
                }
                .tag(device)
            }
        }
        .pickerStyle(.menu)
        .disabled(!isEnabled)
        .onChange(of: selectedDevice) { _, newValue in
            onDeviceSelected(newValue)
        }
    }
}

#Preview {
    VStack {
        InputDevicePicker(
            selectedDevice: .constant(AudioInputDevice(uid: "1", name: "Built-in Microphone", deviceType: .builtIn)),
            availableDevices: [
                AudioInputDevice(uid: "1", name: "Built-in Microphone", deviceType: .builtIn),
                AudioInputDevice(uid: "2", name: "AirPods Pro", deviceType: .bluetooth),
                AudioInputDevice(uid: "3", name: "USB Mic", deviceType: .usb)
            ],
            onDeviceSelected: { _ in },
            isEnabled: true
        )
    }
    .padding()
}
