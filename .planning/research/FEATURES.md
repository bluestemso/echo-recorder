# Research: Feature Implementation Patterns

## 1. SF Symbols Menu Bar Icons

### Pattern: NSStatusItem with SF Symbol
```swift
// StatusItemController.swift - replace title with image
if let button = statusItem.button {
    button.image = NSImage(
        systemSymbolName: "waveform",
        accessibilityDescription: "EchoRecorder"
    )?.withSymbolConfiguration(
        NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
    )
}
```

### Pattern: State-Based Icon Changes
```swift
// Bind to recorder state via Combine
recorderCoordinator.$state
    .receive(on: RunLoop.main)
    .sink { [weak self] state in
        self?.updateStatusItemIcon(for: state)
    }
```

### Recording States
| State | Symbol | Color |
|-------|--------|-------|
| Idle | `waveform` or `mic.fill` | Template (system) |
| Recording | `record.circle.fill` | Red (`.systemRed`) |
| Preparing | `ellipsis.circle` | Template |
| Finalizing | `arrow.triangle.2.circlepath` | Template |

---

## 2. Recording State Indicator (Red Background)

### Pattern: Custom NSView for Status Bar Button
```swift
final class RecordingStatusView: NSView {
    var isRecording: Bool = false {
        didSet { needsDisplay = true }
    }
    
    var symbolName: String = "waveform" {
        didSet { needsDisplay = true }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if isRecording {
            NSColor.systemRed.withAlphaComponent(0.15).setFill()
            let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 2), xRadius: 4, yRadius: 4)
            bgPath.fill()
        }
        
        // Draw SF Symbol centered
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            image.withSymbolConfiguration(config)?
                .draw(in: bounds.insetBy(dx: 6, dy: 4))
        }
    }
}
```

### Usage in StatusItemController
```swift
let recordingView = RecordingStatusView(frame: NSRect(x: 0, y: 0, width: 24, height: 18))
statusItem.button?.addSubview(recordingView)
// Bind to state changes
```

---

## 3. Popover Design Improvements

### Pattern: Animated State Transitions
```swift
struct RecordingPopoverView: View {
    @ObservedObject var viewModel: RecordingViewModel
    
    var body: some View {
        ZStack {
            // Content layers with transitions
            if viewModel.pendingFinalize != nil {
                FinalizeContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                RecordingContent
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.pendingFinalize != nil)
    }
}
```

### Pattern: Improved FinalizeView
```swift
struct FinalizeView: View {
    // ... existing properties
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            // Header with icon
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                Text("Recording Complete")
                    .font(.headline)
            }
            
            // Recording name (editable)
            TextField("Name", text: $viewModel.recordingName)
                .textFieldStyle(.roundedBorder)
            
            // Save location
            HStack {
                Label(viewModel.displayPath, systemImage: "folder")
                    .font(.caption)
                    .lineLimit(1)
                
                Spacer()
                
                Button("Change") { viewModel.chooseDirectory() }
                    .buttonStyle(.borderless)
            }
            
            // Action buttons
            HStack {
                Button("Discard") { /* delete temp file */ }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Save") { onSave() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

---

## 4. Popover Animation Speed

### Pattern: Instant Popover Show/Hide
```swift
// In StatusItemController init:
popover.animates = false  // Disable default animation

// Alternative: SwiftUI wrapper with animation control
struct InstantPopover<Content: View>: NSViewRepresentable {
    let isPresented: Bool
    let content: () -> Content
    
    func makeNSViewRepresentable(context: Context) -> some NSView {
        // Custom implementation if needed
    }
}
```

### Pattern: Fast Content Transitions
```swift
// Use withAnimation with very short duration:
withAnimation(.linear(duration: 0.1)) {
    showFinalizeView = true
}

// Or disable animation entirely for state changes:
withAnimation(.none) {
    state = .finalizing
}
```

---

## 5. Input Source Selection

### Pattern: Device Enumeration Service
```swift
protocol AudioInputDeviceProvider {
    func availableInputDevices() -> [InputDevice]
    func setPreferredInput(_ deviceID: AudioDeviceID) throws
    func defaultBuiltInMicrophone() -> AudioDeviceID?
}

struct InputDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    let isBuiltIn: Bool
}
```

### Pattern: Device Selection in ViewModel
```swift
@Published var availableDevices: [InputDevice] = []
@Published var selectedDeviceID: AudioDeviceID?

func refreshDevices() {
    availableDevices = deviceProvider.availableInputDevices()
    // Default to built-in mic
    if selectedDeviceID == nil {
        selectedDeviceID = availableDevices.first { $0.isBuiltIn }?.id
    }
}
```

### Pattern: Device Selection UI
```swift
struct DevicePickerView: View {
    @Binding var selectedDeviceID: AudioDeviceID?
    let devices: [InputDevice]
    
    var body: some View {
        Picker("Microphone", selection: $selectedDeviceID) {
            ForEach(devices) { device in
                HStack {
                    Image(systemName: device.isBuiltIn ? "laptopcomputer" : "headphones")
                    Text(device.name)
                }
                .tag(device.id as AudioDeviceID?)
            }
        }
    }
}
```

### Pattern: Apply Device Selection
```swift
// In AVAudioEngineAdapter or MicCaptureService:
func setInputDevice(_ deviceID: AudioDeviceID) throws {
    try audioEngine.inputNode.auAudioUnit.setDeviceID(deviceID)
}

// Must restart engine after device change:
engine.stop()
engine.inputNode.removeTap(onBus: 0)
try engine.start()
```

---

## Integration Checklist

- [ ] SF Symbols: Import `AppKit`, use `NSImage(systemSymbolName:)`
- [ ] Red indicator: Create `RecordingStatusView` subclass
- [ ] Popover design: Add state-based transitions in SwiftUI
- [ ] Animation speed: Set `popover.animates = false`
- [ ] Input selection: Create `AudioInputDeviceProvider` protocol, enumerate with CoreAudio
