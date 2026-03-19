---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: milestone
status: completed
last_updated: "2026-03-19T14:13:42.888Z"
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 4
  completed_plans: 4
---

# STATE.md

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-03-18)

**Core value:** User can start a recording in two clicks, monitor and adjust levels live, and reliably get named, organized output files when they stop.
**Current milestone:** v2.0 — UX Polish & Input Selection

---

## Current Position

Phase: 06 (TBD UX Polish) — NOT STARTED
Plan: 0 of 1
Status: Phase 05 complete; deferred recording-contrast follow-up logged in phase artifacts

---

## Planning Artifacts

| Artifact | Path |
|---------|------|
| Project context | `.planning/PROJECT.md` |
| Config | `.planning/config.json` |
| Research | `.planning/research/` |
| Requirements | `.planning/REQUIREMENTS.md` |
| Roadmap | `.planning/ROADMAP.md` |
| Codebase map | `.planning/codebase/` |

---

## Phase Status

| Phase | Name | Status |
|-------|------|--------|
| 4 | Input Source Selection | ✅ Complete |
| 5 | Menu Bar Iconography & Recording Indicator | ✅ Complete (2/2 plans) |
| 6 | TBD (UX Polish) | ⏳ Not started |

---

## Decisions Made

- Used String ID-based Picker binding to avoid needing Hashable conformance on AudioInputDevice
- Settings section uses expand/collapse pattern with chevron indicator and animation
- Error state uses case-insensitive matching for device-related keywords
- Used Core Audio HAL APIs for macOS device enumeration instead of iOS-only AVAudioSession
- Device selection via kAudioHardwarePropertyDefaultInputDevice (system-wide, restored after stop) rather than unavailable AVAudioEngine-specific API
- UID resolution via kAudioHardwarePropertyDeviceForUID before setting default device
- [Phase 05]: Kept recorder state visual mapping as a pure function to lock iconography semantics before AppKit wiring
- [Phase 05]: Added exhaustive mapper tests asserting symbol name, medium weight, pill visibility, accessibility labels, and animation flags for all states
- [Phase 05]: Kept status item updates directly bound to RecorderCoordinator state on RunLoop.main to satisfy <=100ms update latency
- [Phase 05]: Used Core Animation opacity pulse with finite preparing/finalizing loops and continuous recording animation for smoother menu bar behavior
- [Phase 05]: Accepted recording contrast issue as deferred backlog per user request while approving finalizing visibility fix

## Key Accomplishments

- 04-01: Created InputDeviceService with Core Audio enumeration, built-in mic detection, JSONStore persistence; wired RecorderCoordinator and RecordingViewModel
- 04-02: Added InputDevicePicker UI component with device type badges
- Added inline settings section to RecordingPopoverView
- 05-01: Added StatusItemVisualState mapper contract and exhaustive state-to-icon/pill/accessibility tests
- 05-02: Wired state-driven status item rendering with recording pill, smoother animation, and latency/appearance/accessibility controller tests

---

*Milestone v2.0 started: 2026-03-18*
*Phase 04 completed: 2026-03-18*
*Phase 05 completed: 2026-03-19*
