---
phase: 06-popover-ux-improvements
plan: 01
subsystem: ui
tags: [swiftui, popover, finalize-flow, xctest]
requires:
  - phase: 05-menu-bar-iconography-recording-indicator
    provides: status item state rendering and recording lifecycle surface used by finalize entry
provides:
  - finalize-first panel with editable recording name and explicit save/success states
  - deterministic finalize state machine in RecordingViewModel
  - regression tests for finalize copy, timing, and edited-name finalize path
affects: [06-02, finalize transition policy, output robustness]
tech-stack:
  added: []
  patterns: ["FinalizeUIState enum (editing/saving/success)", "pendingFinalizeName binding from view model to finalize view"]
key-files:
  created:
    - EchoRecorderTests/UI/FinalizeViewStateTests.swift
  modified:
    - EchoRecorder/UI/Finalize/FinalizeView.swift
    - EchoRecorder/UI/MenuBar/RecordingViewModel.swift
    - EchoRecorderTests/UI/RecordingRuntimeFlowTests.swift
    - EchoRecorderTests/UI/RecordingViewModelTests.swift
key-decisions:
  - "Made `FinalizeView` bind recording name so user edits are source-of-truth for finalizeRecording(recordingName:)"
  - "Delayed finalize reset by centralized 1.5s timing constant so success feedback is visible before returning idle"
patterns-established:
  - "Finalize flow only clears pending finalize after success delay or explicit failure handling"
  - "Finalize UX contract strings are asserted via test constants to prevent copy regressions"
requirements-completed: [POPOV-01, POPOV-02, POPOV-03]
duration: 21min
completed: 2026-03-19
---

# Phase 06 Plan 01: Finalize UX Contract Summary

**Finalize panel now uses editable naming, explicit saving/success feedback, and deterministic post-save reset behavior.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-03-19T16:31:05Z
- **Completed:** 2026-03-19T16:51:53Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Replaced finalize row UI with finalize-first panel containing editable name, location context, and full-width `Save Recording` action.
- Implemented finalize state machine (`editing`, `saving`, `success`) with 1.5-second success visibility before idle reset.
- Added/greened finalize contract tests for label/copy correctness, success timing observation, and edited-name finalize call path.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Wave 0 finalize UX test scaffolds** - `c86bf9d` (test)
2. **Task 2: Implement finalize-first panel with editable name, save progress, and success morph** - `897629e` (feat)
3. **Task 3: Green the finalize UX test suite and lock regressions** - `897629e` (feat)

_Note: Tasks 2 and 3 landed in one commit while completing TDD greening during implementation._

## Files Created/Modified
- `EchoRecorder/UI/Finalize/FinalizeView.swift` - Added editable finalize form and state-driven action/success UI.
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` - Added finalize UI state/pending name handling and delayed reset behavior.
- `EchoRecorderTests/UI/FinalizeViewStateTests.swift` - Added finalize view contract assertions.
- `EchoRecorderTests/UI/RecordingRuntimeFlowTests.swift` - Added success-visible-before-reset timing test.
- `EchoRecorderTests/UI/RecordingViewModelTests.swift` - Added edited-name forwarding finalize assertion with test doubles.

## Decisions Made
- Bound finalize name edits directly to view-model `pendingFinalizeName` to prevent stale/derived filename mismatch.
- Kept finalize UI visible on failure by returning to `editing` state instead of dropping pending finalize context.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 01 outputs provide the finalize contract and timing seam required by Plan 02 popover transition policy work.

## Self-Check: PASSED
