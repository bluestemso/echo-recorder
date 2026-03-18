# Research: Stack Additions

## 1. SF Symbols Menu Bar Icons

### APIs Needed
- `NSImage(systemSymbolName:accessibilityDescription:)` - Creates SF Symbol images for `NSStatusItem`
- `NSImage.SymbolConfiguration` - Configure symbol appearance (size, weight, multicolor)
- Template vs original rendering mode for color control

### Stack Additions
```swift
// For colored icons (recording state):
let symbolConfig = NSImage.SymbolConfiguration(paletteColors: [.systemRed])
let image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(symbolConfig)

// For monochrome (idle):
let idleImage = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)
```

**Recommended symbols:**
- Idle: `waveform` or `mic.fill`
- Recording: `record.circle.fill`
- Finalizing: `ellipsis.circle.fill`

### Confidence: High - Standard macOS pattern

---

## 2. Recording State Indicator (Red Background)

### APIs Needed
- None new - uses existing `RecorderState` enum
- `NSStatusBarButton` custom drawing via `NSView` subclass OR background color overlay

### Implementation Options
1. **Custom NSView** - Override `draw(_:)` to paint red background
2. **NSImage with composite** - Layer colored image behind symbol
3. **SwiftUI MenuBarExtra** (macOS 13+) - Easier styling, but requires full SwiftUI rewrite

**Recommended:** Option 1 - lightweight custom view that wraps SF Symbol image.

### Confidence: High

---

## 3. Popover Design Improvements

### APIs Needed
- SwiftUI view transitions and animations
- `@ViewBuilder` with conditional content
- `.animation(_:value:)` for smooth state transitions

### Stack Additions
```swift
// Recommended FinalizeView improvements:
// 1. Larger, clearer action buttons
// 2. Progress indicator during save
// 3. Success/error feedback state
// 4. Smooth transition from recording to finalize:

.transition(.asymmetric(
    insertion: .opacity.combined(with: .scale(scale: 0.95)),
    removal: .opacity
))
```

### Post-Recording View States
1. **Recording** - Level meters, stop button
2. **Processing** - Spinner, "Finalizing..." text
3. **Ready to Save** - FinalizeView with name, location, Save button
4. **Success** - Checkmark, "Saved" confirmation, auto-dismiss

### Confidence: High

---

## 4. Popover Animation Speed

### APIs Needed
- `NSPopover.animates` property
- SwiftUI `.animation(_:value:)` modifiers
- `NSAnimationContext` for custom AppKit animations

### Speed Improvements
```swift
// Disable popover entrance animation:
popover.animates = false

// Or speed up SwiftUI transitions:
.withAnimation(.easeOut(duration: 0.15))
```

### Recommendations
1. Disable `NSPopover.animates` for instant show/hide
2. Use fast (150ms) transitions for content changes
3. Respect `NSAnimationContext` duration for resize animations

### Confidence: Medium - Animation tuning is empirical

---

## 5. Input Source Selection (Audio Device)

### APIs Needed
**CoreAudio (macOS):**
```swift
import CoreAudio

// List input devices:
var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDevices,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)

// Check if device has input channels:
kAudioDevicePropertyStreamConfiguration
kAudioDevicePropertyDeviceNameCFString
```

**AVAudioEngine device selection (macOS):**
```swift
// Method 1: Set via AUAudioUnit (preferred for macOS)
try audioEngine.inputNode.auAudioUnit.setDeviceID(deviceId)

// Method 2: Create aggregate device (complex but reliable)
// See: https://stackoverflow.com/questions/61827898
```

### Built-in Mic Detection
```swift
func isBuiltInMicrophone(_ deviceID: AudioDeviceID) -> Bool {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceNameCFString,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var name: CFString = "" as CFString
    var dataSize = UInt32(MemoryLayout<CFString>.size)
    
    let status = AudioObjectGetPropertyData(
        deviceID, &propertyAddress, 0, nil, &dataSize, &name
    )
    
    if status == noErr {
        let nameStr = name as String
        return nameStr.contains("MacBook") || 
               nameStr.contains("Built-in") ||
               nameStr.contains("Internal Microphone")
    }
    return false
}
```

### Recommended Approach
1. List all input devices via CoreAudio
2. Default to built-in mic if available
3. Store selected device ID in `AppSettings`
4. Recreate `AVAudioEngine` adapter when device changes

### Confidence: Medium - CoreAudio API is verbose but well-documented

---

## Summary

| Feature | New APIs | Complexity |
|---------|----------|------------|
| SF Symbols icons | NSImage(systemSymbolName:) | Low |
| Red recording indicator | Custom NSView | Low |
| Popover design | SwiftUI animations | Low |
| Animation speed | NSPopover.animates | Low |
| Input source selection | CoreAudio | Medium |
