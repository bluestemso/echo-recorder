---
phase: 05-menu-bar-iconography-recording-indicator
plan: 01
subsystem: ui
tags: [appkit, sf-symbols, menu-bar, xctest]
requires:
  - phase: 04-input-source-selection
    provides: recorder state publishing and menu bar controller integration points
provides:
  - Deterministic RecorderState to menu bar visual-state mapper
  - Exhaustive unit coverage for icon, pill visibility, animation, and accessibility labels
affects: [05-02, status-item-controller, menu-bar-visual-rendering]
tech-stack:
  added: []
  patterns: [pure visual-state mapping, recorder-state exhaustive assertions]
key-files:
  created:
    - EchoRecorder/UI/MenuBar/StatusItemVisualState.swift
  modified:
    - EchoRecorderTests/UI/StatusItemVisualStateTests.swift
    - EchoRecorder.xcodeproj/project.pbxproj
key-decisions:
  - "Kept state-to-visual logic as a pure function to lock iconography semantics before AppKit wiring"
  - "Validated every RecorderState in tests, including accessibility labels and recording pill transitions"
patterns-established:
  - "Status icon behavior is controlled through statusItemVisualState(for:appName:) switch over all RecorderState cases"
  - "Mapping regression tests assert symbol name, medium weight, pill visibility, palette mode, labels, and animation flags"
requirements-completed: [ICON-01, ICON-02, ICON-03, IND-01, IND-03]
duration: 5min
completed: 2026-03-19
---

# Phase 05 Plan 01: Menu Bar Icon Contract Summary

**RecorderState now maps deterministically to menu bar SF Symbols, recording-pill visibility, and accessibility labels with exhaustive XCTest enforcement.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-19T02:59:16Z
- **Completed:** 2026-03-19T03:04:11Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added `StatusItemVisualState` contract with explicit fields for symbol, weight, pill visibility, palette mode, accessibility text, and animation intent.
- Implemented `statusItemVisualState(for:appName:)` as a complete `RecorderState` switch with locked symbol names and labels for all five states.
- Added exhaustive `StatusItemVisualStateTests` coverage with required test methods and state-by-state assertions for ICON-01/02/03 and IND-01/03 behaviors.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add StatusItemVisualState contract and pure mapper** - `208cf4e`, `87d7703` (test, feat)
2. **Task 2: Create exhaustive mapper tests and assertions** - `d33e758`, `fd6b5a3` (test, test)

## Files Created/Modified
- `EchoRecorder/UI/MenuBar/StatusItemVisualState.swift` - Defines visual-state model and deterministic mapper for every recorder state.
- `EchoRecorderTests/UI/StatusItemVisualStateTests.swift` - Enforces icon/pill/label/animation mapping invariants with exhaustive assertions.
- `EchoRecorder.xcodeproj/project.pbxproj` - Regenerated so newly added source/test files are included in build targets.

## Decisions Made
- Used `NSFont.Weight` in the mapper contract so symbol weight remains concrete and directly assertable from tests.
- Kept red indicator semantics strict (`showRecordingPill == true` only for `.recording`) and codified this in dedicated transition-focused tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated Xcode project to include newly created source and test files**
- **Found during:** Task 1
- **Issue:** Newly added test file was not compiled until `EchoRecorder.xcodeproj/project.pbxproj` was regenerated.
- **Fix:** Ran `xcodegen generate` and committed resulting project file updates.
- **Files modified:** `EchoRecorder.xcodeproj/project.pbxproj`
- **Verification:** RED test run failed on missing mapper symbols after project regeneration, then passed after implementation.
- **Committed in:** `208cf4e`, `87d7703`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Deviation was required for correctness of build/test inclusion and did not change scope.

## Issues Encountered
- None.

## Auth Gates Encountered
- None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Visual mapping contract is fully locked and tested, so Phase 05-02 can wire AppKit status item rendering against this mapper without ambiguity.
- No blockers identified for proceeding to controller integration work.

## Self-Check: PASSED
- Verified summary file exists at `.planning/phases/05-menu-bar-iconography-recording-indicator/05-01-SUMMARY.md`.
- Verified all task commit hashes exist: `208cf4e`, `87d7703`, `d33e758`, `fd6b5a3`.

---
*Phase: 05-menu-bar-iconography-recording-indicator*
*Completed: 2026-03-19*
