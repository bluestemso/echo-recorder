# Research: Common Pitfalls

## 1. SF Symbols in NSStatusItem

### Pitfall: Template Images Override Color
**Problem:** Using `.isTemplate = true` on SF Symbol images makes them monochrome, ignoring color settings.

**Solution:**
```swift
// Don't set isTemplate for colored icons
button.image = NSImage(systemSymbolName: "record.circle.fill", ...)
// button.image?.isTemplate = true  // REMOVE THIS LINE
```

### Pitfall: Image Sizing
**Problem:** SF Symbols may render too large/small in status bar.

**Solution:**
```swift
// Use SymbolConfiguration for precise sizing
image.withSymbolConfiguration(
    NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
)
```

### Pitfall: Menu Bar Clipping
**Problem:** Icons get clipped on screens with "automatic" menu bar location.

**Solution:** Keep icon size 18x18pt max. Test on Retina/Non-Retina displays.

---

## 2. Recording State Indicator

### Pitfall: Drawing on Wrong Thread
**Problem:** `RecordingStatusView.draw()` may be called from wrong thread.

**Solution:**
```swift
override func draw(_ dirtyRect: NSRect) {
    DispatchQueue.main.async {
        self.needsDisplay = true
        return
    }
    // ... actual drawing on main thread
}
```

### Pitfall: Redraw Not Triggering
**Problem:** Background doesn't update when state changes.

**Solution:** Call `needsDisplay = true` in property `didSet`:
```swift
var isRecording: Bool = false {
    didSet {
        needsDisplay = true
    }
}
```

---

## 3. Popover Design

### Pitfall: Z-Order with Overlay Views
**Problem:** SwiftUI overlays (alerts, sheets) appear behind popover.

**Solution:** Use `.zIndex()` modifier:
```swift
finalizeView
    .zIndex(10)
```

### Pitfall: Content Size Not Updating
**Problem:** Popover doesn't resize when content changes.

**Solution:**
```swift
// In NSPopover:
popover.contentSize = NSSize(width: 280, height: newHeight)

// Or in SwiftUI:
.id(viewModel.popoverContentID)  // Force rebuild on change
```

### Pitfall: Animation Stutter
**Problem:** Animations stutter when heavy computation runs.

**Solution:**
- Keep animations on main thread
- Use `Transaction.animation = nil` for instant changes
- Defer non-critical updates

---

## 4. Popover Animation Speed

### Pitfall: Animates Property Not Working
**Problem:** `popover.animates = false` doesn't disable all animations.

**Solution:**
```swift
// Also disable view animations:
NSAnimationContext.current.allowsImplicitAnimation = false
```

### Pitfall: SwiftUI Animation Still Active
**Problem:** SwiftUI `.animation()` modifier overrides `NSPopover.animates`.

**Solution:** Use `animation(nil)` for specific views:
```swift
content
    .animation(nil, value: shouldAnimate)
```

### Pitfall: Respects Reduce Motion
**Problem:** Force-fast animations may violate accessibility settings.

**Solution:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

if reduceMotion {
    // Use instant transitions
} else {
    // Use animated transitions
}
```

---

## 5. Input Source Selection (Audio Device)

### Pitfall: AVAudioEngine Device Change Requires Restart
**Problem:** Setting new device while engine is running causes error.

**Solution:**
```swift
func changeInputDevice(_ deviceID: AudioDeviceID) throws {
    engine.stop()  // Stop first
    engine.inputNode.removeTap(onBus: 0)
    try engine.inputNode.auAudioUnit.setDeviceID(deviceID)
    try engine.start()
    installTap(currentHandler)
}
```

### Pitfall: Bluetooth Audio Latency/Quality
**Problem:** Bluetooth devices may have high latency, low quality, or disconnect.

**Solution:**
```swift
// Check device transport type
var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioDevicePropertyTransportType,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)
var transportType: UInt32 = 0
var dataSize = UInt32(MemoryLayout<UInt32>.size)
AudioObjectGetPropertyData(deviceID, &propertyAddress, ...)

// kAudioDeviceTransportTypeBluetooth = "bluetooth"
// Show warning to user if Bluetooth selected
```

### Pitfall: Device Enumeration Race Condition
**Problem:** Devices can connect/disconnect while enumerating.

**Solution:**
```swift
// Register for device change notifications:
AudioObjectAddPropertyListener(
    AudioObjectID(kAudioObjectSystemObject),
    &propertyAddress,
    { deviceID, addresses, clientData in
        // Post notification on main queue
    }
)
```

### Pitfall: Aggregate Devices on Apple Silicon
**Problem:** Some USB/Bluetooth devices appear as aggregate, confusing enumeration.

**Solution:**
```swift
// Filter aggregate devices:
if transportType == kAudioDeviceTransportTypeUSB ||
   transportType == kAudioDeviceTransportTypeBuiltIn ||
   transportType == kAudioDeviceTransportTypeBluetooth {
    // Include in list
}
```

### Pitfall: Default Device Changes While App Running
**Problem:** System default changes (e.g., headphones connected) affect our selection.

**Solution:**
```swift
// Listen for default device changes:
AudioObjectAddPropertyListener(
    AudioObjectID(kAudioObjectSystemObject),
    &kAudioHardwarePropertyDefaultInputDevice,
    // Update UI to reflect system default
)
```

### Pitfall: Permission Required for Non-Default Devices
**Problem:**麦克风 permission may be requested again when switching devices.

**Solution:**
- Check permission status before starting capture
- Request permission early (during device selection)
- Show appropriate UI if permission denied

---

## General macOS Menu Bar App Pitfalls

### Pitfall: App Sandbox Restrictions
**Problem:** Sandbox may restrict CoreAudio access.

**Solution:** Add entitlements:
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

### Pitfall: LSUIElement Not Set
**Problem:** App appears in Dock when it should be menu bar only.

**Solution:** In Info.plist:
```xml
<key>LSUIElement</key>
<true/>
```

### Pitfall: Memory Pressure in Menu Bar Apps
**Problem:** Menu bar apps are often kept running; memory leaks compound.

**Solution:**
- Use weak references where appropriate
- Clean up timers and observers on deinit
- Profile with Instruments regularly

---

## Testing Checklist

- [ ] Test SF Symbols render correctly in light/dark mode
- [ ] Test recording indicator on non-Retina displays
- [ ] Test popover animation with accessibility Reduce Motion enabled
- [ ] Test Bluetooth device disconnect during recording
- [ ] Test with multiple audio devices connected/disconnected
- [ ] Test memory usage over extended recording sessions
- [ ] Test popover behavior with VoiceOver enabled
