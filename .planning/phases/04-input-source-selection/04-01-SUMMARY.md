---
phase: 04-input-source-selection
plan: "01"
subsystem: audio
tags: [coreaudio, avfoundation, device-enumeration, dependency-injection]

requires:
  - phase: "03-save-location-picker"
    provides: "JSONStore, Profile model, dependency injection pattern"
provides:
  - "AudioInputDeviceService: Core Audio device enumeration, built-in mic detection, JSONStore persistence"
  - "MicCaptureEngine protocol extended with selectDevice capability"
  - "RecorderCoordinator wired to InputDeviceService for device selection at recording start"
  - "RecordingViewModel exposes selectedDevice and availableInputDevices for UI binding"
affects: [04-02-input-source-ui]

tech-stack:
  added: [CoreAudio, kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultInputDevice]
  patterns: [service-wrappers, dependency-injection, protocol-delegation]

key-files:
  created:
    - EchoRecorder/Core/Audio/InputDeviceService.swift
  modified:
    - EchoRecorder/Core/Audio/MicCaptureService.swift
    - EchoRecorder/Core/Recording/RecorderCoordinator.swift
    - EchoRecorder/UI/MenuBar/RecordingViewModel.swift

key-decisions:
  - "Used Core Audio HAL APIs (kAudioHardwarePropertyDevices) instead of iOS AVAudioSession for macOS device enumeration"
  - "Set default input device via kAudioHardwarePropertyDefaultInputDevice before engine start, restore after stop"
  - "InputDeviceService follows same service wrapper pattern as SaveLocationService"

patterns-established:
  - "Service wrapper pattern: private let store: JSONStore, static let key, init(store:), computed properties"
  - "Device selection: UID resolution via kAudioHardwarePropertyDeviceForUID, device switching via kAudioHardwarePropertyDefaultInputDevice"

requirements-completed: [INPUT-01, INPUT-02, INPUT-03, INPUT-04, INPUT-05, INPUT-06]

duration: 9min
completed: 2026-03-18
---

# Phase 04 Plan 01: Input Source Selection Backend Summary

**AudioInputDeviceService with Core Audio enumeration, built-in mic detection, and JSONStore persistence; MicCaptureEngine extended for device selection via default input switching**

## Performance

- **Duration:** 9 min
- **Started:** 2026-03-18T21:29:39Z
- **Completed:** 2026-03-18T21:39:36Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Created AudioInputDeviceService using Core Audio HAL for macOS device enumeration (replaced iOS-only AVAudioSession)
- Extended MicCaptureEngine/MicCaptureServicing protocols with selectDevice and selectedDeviceID
- AVAudioEngineAdapter sets/resets default input device via kAudioHardwarePropertyDefaultInputDevice
- Wired RecorderCoordinator to InputDeviceService for automatic device selection at recording start
- Wired RecordingViewModel with inputDeviceService, @Published selectedDevice and availableInputDevices

## Task Commits

Each task was committed atomically:

1. **Task 1: Create InputDeviceService** - `8a3e41f` (feat)
2. **Task 2: Extend MicCaptureEngine** - `e43343a` (feat)
3. **Task 3: Wire RecorderCoordinator and RecordingViewModel** - `53b2d3d` (feat)

**Plan metadata:** [to be committed with this file]

## Files Created/Modified
- `EchoRecorder/Core/Audio/InputDeviceService.swift` - Device enumeration via Core Audio, built-in mic detection, JSONStore persistence
- `EchoRecorder/Core/Audio/MicCaptureService.swift` - MicCaptureEngine protocol extended with selectDevice; AVAudioEngineAdapter sets default input device
- `EchoRecorder/Core/Recording/RecorderCoordinator.swift` - Added inputDeviceService parameter, selectDevice method, device selection in startAudioRecording
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` - Full InputDeviceService integration with @Published selectedDevice and availableInputDevices

## Decisions Made
- Used Core Audio HAL APIs for macOS device enumeration instead of iOS-only AVAudioSession (auto-fix from plan's iOS-specific API references)
- Device selection via kAudioHardwarePropertyDefaultInputDevice (system-wide change, restored after stop) rather than AVAudioEngine-specific API (not available on macOS)
- UID resolution via kAudioHardwarePropertyDeviceForUID before setting default device

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced iOS-only AVAudioSession with macOS Core Audio APIs**
- **Found during:** Task 1 (InputDeviceService creation)
- **Issue:** Plan referenced `AVAudioSession.sharedInstance().availableInputs` which is iOS-only. macOS has no AVAudioSession.
- **Fix:** Implemented Core Audio HAL enumeration via `kAudioHardwarePropertyDevices`, `kAudioDevicePropertyDeviceUID`, `kAudioDevicePropertyDeviceNameCFString`, `kAudioDevicePropertyTransportType`, and input channel filtering via `kAudioDevicePropertyStreamConfiguration`
- **Files modified:** EchoRecorder/Core/Audio/InputDeviceService.swift
- **Verification:** Device enumeration compiles with Core Audio imports
- **Committed in:** `8a3e41f` (Task 1 commit)

**2. [Rule 3 - Blocking] Replaced iOS-only setInputDevice with macOS Core Audio default device switching**
- **Found during:** Task 2 (AVAudioEngineAdapter extension)
- **Issue:** Plan referenced `audioEngine.inputNode.setInputDevice(deviceID)` which doesn't exist on macOS. AVAudioInputNode has no per-session input device selection.
- **Fix:** Implemented device selection via `kAudioHardwarePropertyDefaultInputDevice` (system-wide, with restore on `stop()`) and UID resolution via `kAudioHardwarePropertyDeviceForUID`
- **Files modified:** EchoRecorder/Core/Audio/MicCaptureService.swift
- **Verification:** setInputDevice, resolveDeviceID, getDefaultInputDevice, restoreOriginalDefaultInputDevice methods compile
- **Committed in:** `e43343a` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - Blocking)
**Impact on plan:** Both deviations replaced iOS-only APIs with correct macOS Core Audio equivalents. No scope change—functionality is identical, platform-appropriate implementation only.

## Issues Encountered
- None — plan executed smoothly with auto-fixes for platform-specific API differences

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- InputDeviceService ready for 04-02 UI plan
- `selectedDevice` and `availableInputDevices` @Published on RecordingViewModel for SwiftUI binding
- `setSelectedDevice(_:)` method on RecordingViewModel for user device selection
- `RecorderCoordinator.selectDevice(_:)` available for direct device override

---
*Phase: 04-input-source-selection / Plan 01*
*Completed: 2026-03-18*
