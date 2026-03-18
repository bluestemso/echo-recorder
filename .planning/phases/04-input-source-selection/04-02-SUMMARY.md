---
phase: 04-input-source-selection
plan: "02"
subsystem: ui
tags: [swiftui, audio, device-selection, picker, popover]

# Dependency graph
requires:
  - phase: 04-input-source-selection
    provides: InputDeviceService with AudioInputDevice, DeviceType types
provides:
  - InputDevicePicker SwiftUI component with device name and type badge
  - RecordingPopoverView inline settings section with expandable device picker
affects: [ui, menu-bar]

# Tech tracking
tech-stack:
  added: [SwiftUI Picker, Binding, @ViewBuilder]
  patterns: [expandable settings section, device picker with type badges]

key-files:
  created:
    - EchoRecorder/UI/MenuBar/InputDevicePicker.swift
  modified:
    - EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
    - EchoRecorder/UI/MenuBar/RecordingViewModel.swift

key-decisions:
  - Used String ID-based Picker binding to avoid needing Hashable conformance on AudioInputDevice
  - Expandable settings section visible only when idle (not recording)

patterns-established:
  - "Device picker pattern: Menu-style picker with name + colored type badge"
  - "Inline settings pattern: Expandable section with chevron indicator and animation"

requirements-completed: [INPUT-01, INPUT-02, INPUT-03, INPUT-04, INPUT-05, INPUT-06]

# Metrics
duration: 5 min
completed: 2026-03-18
---

# Phase 4 Plan 2: Input Device Picker UI Summary

**InputDevicePicker SwiftUI component with expandable inline settings in RecordingPopoverView, using String ID-based binding for device selection**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-18T21:29:39Z
- **Completed:** 2026-03-18T21:35:31Z
- **Tasks:** 2
- **Files modified:** 4 (InputDevicePicker created, RecordingPopoverView updated, RecordingViewModel updated, AudioInputDevice stub removed)

## Accomplishments
- Created InputDevicePicker with Picker-style selection and device type badges
- Added expandable inline settings section to RecordingPopoverView
- Settings section visible only when idle (not recording)
- Error state warning for device/input issues
- Uses real types from InputDeviceService.swift (04-01)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create InputDevicePicker SwiftUI component** - `bdcc4e0` (feat)
   - Created InputDevicePicker with Picker-style selection
   - Added DeviceTypeBadge showing "Built-in"/"USB"/"Bluetooth"/"Other"
   - Badge colors: gray, blue, purple based on type
   - Uses String ID-based Binding (avoids needing Hashable)
   - Includes #Preview with sample devices

2. **Task 2: Add inline settings section to RecordingPopoverView** - `c0783b2` (feat)
   - Added isShowingInputSettings state for expand/collapse
   - Settings only visible when idle (!isRecording)
   - Shows selected device name with type badge
   - Contains InputDevicePicker bound to viewModel.selectedDevice
   - Chevron indicator rotates on expand
   - Error warning shown for device issues

## Files Created/Modified
- `EchoRecorder/UI/MenuBar/InputDevicePicker.swift` - Device picker UI with name and type badge
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` - Added inline settings section with device picker
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` - Added stub properties for selectedDevice and availableInputDevices (to be wired in 04-03)

## Decisions Made
- Used String ID-based Picker binding to avoid modifying AudioInputDevice to add Hashable conformance
- Settings section uses expand/collapse pattern with chevron indicator
- Error state uses case-insensitive matching for device-related keywords

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Stub types file conflicted with 04-01 real implementation**
- **Found during:** Task 1 (InputDevicePicker)
- **Issue:** Created AudioInputDevice.swift stub, but 04-01 already had the real types in InputDeviceService.swift
- **Fix:** Removed AudioInputDevice.swift stub, updated InputDevicePicker to use types from InputDeviceService.swift
- **Files modified:** EchoRecorder/Core/Audio/AudioInputDevice.swift (deleted), EchoRecorder/UI/MenuBar/InputDevicePicker.swift (updated)
- **Verification:** InputDevicePicker compiles with real types from InputDeviceService.swift
- **Committed in:** bdcc4e0 (amended commit)

---

**Total deviations:** 1 auto-fixed (blocking)
**Impact on plan:** Removed conflicting stub file, UI uses real types from 04-01 backend. Minor delay but ensures clean integration.

## Issues Encountered
- None - plan executed smoothly once stub type conflict was resolved

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- InputDevicePicker UI complete and ready
- Backend (04-01) provides AudioInputDeviceService with Core Audio enumeration
- RecordingViewModel has stub properties that need wiring in 04-03
- Ready for 04-03: Wire RecordingViewModel to real InputDeviceService

---
*Phase: 04-input-source-selection*
*Completed: 2026-03-18*
