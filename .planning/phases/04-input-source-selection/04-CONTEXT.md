# Phase 4: Input Source Selection - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Add input source selection with fallback to built-in microphone. Users can see available audio input devices, select which one to use, and the selection persists across app restarts. Recording works when Bluetooth headphones are connected (fixes the current bug).

</domain>

<decisions>
## Implementation Decisions

### Device Selection UI
- Device picker is always visible in the recording popover when idle
- Picker shows name + type badge for each device (e.g., "Built-in", "USB", "Bluetooth")
- Picker is hidden during active recording (only visible when idle)
- Simple toggle to expand inline settings section

### Settings Location
- Settings accessed via a simple toggle that expands an inline settings section in the popover
- Settings section expands inline below main controls (not a full replacement or modal)
- Record button is always visible even when settings is expanded

### Fallback Behavior
- If selected device is unavailable when recording starts: show error toast with an auto-fix button
- Built-in microphone detected by device name containing "Built-in", "MacBook", or "Internal Microphone" (matches INPUT-04 requirement)
- If built-in mic is also unavailable (edge case): warn user but proceed with recording
- Error/warning appears as a toast/banner in the popover

### Device Switching
- Users can only switch devices when app is idle (not during recording)
- When saved device becomes unavailable while app is idle: prompt user on next app open
- Prompt manifests as auto-expanded settings section with a message
- After successful device switch: just update the displayed device name (no extra feedback)

### Claude's Discretion
- Exact picker component style (native macOS picker vs custom SwiftUI)
- Device type badge design and colors
- Toast animation and auto-dismiss timing
- What text the auto-fix button shows

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `REQUIREMENTS.md` §INPUT-01 to INPUT-06 — Input source selection requirements
- `ROADMAP.md` §Phase 4 — Phase goal and success criteria

### Existing Code
- `EchoRecorder/Core/Audio/MicCaptureService.swift` — `MicCaptureEngine` protocol, `AVAudioEngineAdapter` (needs device selection extension)
- `EchoRecorder/Core/Audio/MicCaptureService.swift:71-73` — Current hardcoded `audioEngine.inputNode` tap
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` — `InputSource` enum, gain state management pattern to follow
- `EchoRecorder/Core/Models/Profile.swift:12` — `micDeviceID: String?` field already exists but unused
- `EchoRecorder/Core/Persistence/JSONStore.swift` — Persistence pattern (used for save location, follow same pattern)
- `EchoRecorder/Core/Persistence/SaveLocationService.swift` — Service wrapper pattern for JSONStore

### Prior Phase Context
- `.planning/phases/03-save-location-picker/03-CONTEXT.md` — JSONStore + service wrapper pattern for persistence

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `JSONStore` + service wrapper pattern — use for persisting selected device ID
- `SaveLocationService` — reference pattern for device persistence service
- `RecordingViewModel.InputSource` enum — already distinguishes mic from system audio

### Established Patterns
- `@Published` properties on `RecordingViewModel` for UI bindings
- Settings toggle uses existing gain slider section as design reference
- Toast/banner pattern not yet in codebase — will need to implement

### Integration Points
- `AVAudioEngineAdapter` needs device selection capability (currently hardcoded to default input)
- `RecorderCoordinator.startAudioRecording()` calls `mic.startCapture()` without device selection
- `Profile.micDeviceID` is already plumbed through but not used
- Device picker UI in `RecordingPopoverView` or new `InputSettingsView`

### Technical Notes
- AVAudioEngine supports device selection via `setInputDevice()` on the input node
- `AVAudioSession.sharedInstance().availableInputs` gives list of input devices
- Device UID is stable across sessions; name can change

</code_context>

<specifics>
## Specific Ideas

- Bluetooth headphones issue: The app currently defaults to `audioEngine.inputNode` which may not select the user's preferred device when Bluetooth headphones are connected
- Device selection should match the expected behavior where "Bluetooth microphone" can be explicitly selected

</specifics>

<deferred>
## Deferred Ideas

- Video recording with audio input selection — future phase
- Multiple simultaneous input devices — explicitly out of scope per REQUIREMENTS.md
- Device testing/debug view — nice-to-have for troubleshooting

</deferred>

---

*Phase: 04-input-source-selection*
*Context gathered: 2026-03-18*
