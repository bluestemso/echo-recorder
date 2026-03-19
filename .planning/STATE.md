---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: milestone
status: completed
last_updated: "2026-03-19T03:05:10.057Z"
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 4
  completed_plans: 3
---

# STATE.md

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-03-18)

**Core value:** User can start a recording in two clicks, monitor and adjust levels live, and reliably get named, organized output files when they stop.
**Current milestone:** v2.0 — UX Polish & Input Selection

---

## Current Position

Phase: 05 (Menu Bar Iconography & Recording Indicator) — IN PROGRESS
Plan: 1 of 2
Status: 05-01 complete; ready for 05-02

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
| 5 | Menu Bar Iconography & Recording Indicator | 🔄 In progress (1/2 plans) |
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

---

## Key Accomplishments

- 04-01: Created InputDeviceService with Core Audio enumeration, built-in mic detection, JSONStore persistence; wired RecorderCoordinator and RecordingViewModel
- 04-02: Added InputDevicePicker UI component with device type badges
- Added inline settings section to RecordingPopoverView
- 05-01: Added StatusItemVisualState mapper contract and exhaustive state-to-icon/pill/accessibility tests

---

*Milestone v2.0 started: 2026-03-18*
*Phase 04 completed: 2026-03-18*
