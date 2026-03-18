# Research: Architecture Integration Points

## Existing Architecture Summary

```
AppDelegate
  └── StatusItemController (@MainActor)
        ├── NSStatusItem (AppKit)
        ├── NSPopover
        │     └── NSHostingController<RecordingPopoverView>
        └── RecordingViewModel (@MainActor, ObservableObject)
              ├── RecorderCoordinator (@MainActor)
              │     ├── CaptureService (system audio)
              │     ├── MicCaptureService → AVAudioEngineAdapter
              │     ├── MeteringService
              │     └── AudioMixerService
              └── FinalizeRecordingViewModel
```

---

## Feature 1: SF Symbols Menu Bar Icons

### Integration Point: `StatusItemController`
**File:** `EchoRecorder/UI/MenuBar/StatusItemController.swift`

**Changes:**
1. Replace `statusItem.button?.title` with `statusItem.button?.image`
2. Add `@Published var recordingState: RecorderState` observation
3. Create helper method to generate appropriate SF Symbol

```swift
// New property
private let recordingView: RecordingStatusView

// In init, replace title line:
// statusItem.button?.title = title
statusItem.button?.image = makeIdleImage()
```

### State Binding
```swift
// Add to cancellables
recorderCoordinator.$state
    .sink { [weak self] state in
        self?.updateIcon(for: state)
    }
    .store(in: &cancellables)
```

---

## Feature 2: Recording State Indicator

### Integration Point: Custom NSView Subclass
**New File:** `EchoRecorder/UI/MenuBar/RecordingStatusView.swift`

**Purpose:** Draw red background ring/badge around status item when recording

### Alternative: SwiftUI Overlay
For pure SwiftUI approach, wrap in `NSHostingView`:
```swift
// In StatusItemController init
let hostingView = NSHostingView(rootView: StatusBarIcon(state: .idle))
hostingView.frame = statusItem.button?.bounds ?? .zero
statusItem.button?.addSubview(hostingView)
```

---

## Feature 3: Popover Design Improvements

### Integration Point: `RecordingPopoverView`
**File:** `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift`

**Changes:**
1. Add state-based view transitions using `@ViewBuilder`
2. Enhance `FinalizeView` layout
3. Add success/feedback states

### View Hierarchy
```swift
struct RecordingPopoverView: View {
    @ObservedObject var viewModel: RecordingViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // State-based content
            contentView
                .transition(viewTransition)
            
            // Persistent footer
            footerView
        }
        .padding(12)
        .frame(width: 280)  // Slightly wider for better layout
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            IdleContentView(viewModel: viewModel)
        case .recording:
            RecordingContentView(viewModel: viewModel)
        case .pendingFinalize:
            FinalizeView(viewModel: viewModel.pendingFinalize)
        case .finalizing:
            FinalizingContentView()
        }
    }
}
```

### Integration Point: `FinalizeView`
**File:** `EchoRecorder/UI/Finalize/FinalizeView.swift`

**Changes:**
1. Add success state with checkmark
2. Improve layout spacing
3. Add recording duration display

---

## Feature 4: Popover Animation Speed

### Integration Point: `StatusItemController`
**File:** `EchoRecorder/UI/MenuBar/StatusItemController.swift`

**Changes:**
```swift
// In init, after popover creation:
popover.animates = false

// For content transitions, add animation modifier:
extension Animation {
    static let fastPopover = Animation.easeOut(duration: 0.15)
}

// Apply in RecordingPopoverView:
.animation(.fastPopover, value: viewModel.pendingFinalize)
```

---

## Feature 5: Input Source Selection

### New Component: `AudioDeviceService`
**New File:** `EchoRecorder/Core/Audio/AudioDeviceService.swift`

**Protocol:**
```swift
protocol AudioDeviceServicing {
    var availableInputDevices: [InputDevice] { get }
    var preferredInputDeviceID: AudioDeviceID? { get set }
    
    func refreshDevices()
    func setPreferredInput(_ deviceID: AudioDeviceID) throws
}
```

### Integration Point: `AVAudioEngineAdapter`
**File:** `EchoRecorder/Core/Audio/MicCaptureService.swift`

**Changes:**
1. Add device ID property
2. Implement `setDeviceID()` method
3. Restart engine on device change

```swift
final class AVAudioEngineAdapter: MicCaptureEngine {
    private var selectedDeviceID: AudioDeviceID?
    
    func setDeviceID(_ deviceID: AudioDeviceID) throws {
        try audioEngine.inputNode.auAudioUnit.setDeviceID(deviceID)
        selectedDeviceID = deviceID
    }
    
    func restartWithNewDevice() throws {
        removeTap()
        engine.stop()
        try engine.start()
        installTap(currentHandler)
    }
}
```

### Integration Point: `MicCaptureService`
**File:** `EchoRecorder/Core/Audio/MicCaptureService.swift`

**Changes:**
```swift
protocol MicCaptureServicing {
    // ... existing
    func setInputDevice(_ deviceID: AudioDeviceID) throws
}
```

### Integration Point: `RecordingViewModel`
**File:** `EchoRecorder/UI/MenuBar/RecordingViewModel.swift`

**Changes:**
```swift
@Published var availableInputDevices: [InputDevice] = []
@Published var selectedInputDeviceID: AudioDeviceID?

// Add device selection method
func setInputDevice(_ device: InputDevice) {
    selectedInputDeviceID = device.id
    recorderCoordinator?.setInputDevice(device.id)
}
```

### Integration Point: `RecordingPopoverView`
**File:** `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift`

**Changes:**
Add device picker section when not recording:
```swift
if !viewModel.isRecording {
    DevicePickerView(
        selectedDeviceID: $viewModel.selectedInputDeviceID,
        devices: viewModel.availableInputDevices
    )
}
```

### Integration Point: `RecorderCoordinator`
**File:** `EchoRecorder/Core/Recording/RecorderCoordinator.swift`

**Changes:**
```swift
func setInputDevice(_ deviceID: AudioDeviceID) {
    do {
        try mic.setInputDevice(deviceID)
    } catch {
        // Handle error
    }
}
```

### Persistence: `AppSettings`
**File:** `EchoRecorder/Core/Models/AppSettings.swift`

**Changes:**
```swift
struct AppSettings: Codable {
    // ... existing
    let preferredInputDeviceID: UInt32?  // AudioDeviceID
}
```

---

## Summary: File Changes

| File | Change Type | Purpose |
|------|-------------|---------|
| `StatusItemController.swift` | Modify | SF Symbols, animation speed |
| `RecordingPopoverView.swift` | Modify | Popover design, device picker |
| `FinalizeView.swift` | Modify | Enhanced finalize UI |
| `MicCaptureService.swift` | Modify | Device selection support |
| `AVAudioEngineAdapter` | Modify | Device ID setting |
| `RecorderCoordinator.swift` | Modify | Forward device selection |
| `AppSettings.swift` | Modify | Persist selected device |
| `RecordingStatusView.swift` | **New** | Red recording indicator |
| `AudioDeviceService.swift` | **New** | Device enumeration |
