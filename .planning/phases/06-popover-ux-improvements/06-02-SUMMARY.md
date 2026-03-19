---
phase: 06-popover-ux-improvements
plan: 02
subsystem: ui
tags: [appkit, swiftui, animation, reduce-motion, xctest]
requires:
  - phase: 06-popover-ux-improvements
    provides: finalize-first state machine and post-save timing behavior from plan 01
provides:
  - centralized popover/content timing policy constants
  - near-instant popover show/close fade behavior with explicit animation control
  - reduce-motion-aware finalize transition policy with opacity-only fallback
  - runtime-verified finalize save reliability after AAC encoder fallback fix
affects: [phase-06 closeout, status item UX, output finalization]
tech-stack:
  added: []
  patterns: ["PopoverUXTiming as timing source-of-truth", "animation policy split between content transition and popover presentation"]
key-files:
  created:
    - EchoRecorder/UI/MenuBar/PopoverUXTiming.swift
    - EchoRecorderTests/UI/FinalizeTransitionTimingTests.swift
    - EchoRecorderTests/UI/PopoverAnimationPolicyTests.swift
  modified:
    - EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
    - EchoRecorder/UI/MenuBar/StatusItemController.swift
    - EchoRecorderTests/UI/StatusItemControllerIconTests.swift
    - EchoRecorder/Core/Output/AudioWriterPipeline.swift
    - EchoRecorderTests/Output/AudioWriterPipelineTests.swift
key-decisions:
  - "Disabled default NSPopover animation and applied explicit 75ms alpha fades for consistent near-instant behavior"
  - "Used Reduce Motion policy to remove movement while preserving opacity-based state transitions"
  - "Added adaptive AAC bitrate + no-bitrate fallback write path to prevent finalize failures on low-rate mono inputs"
patterns-established:
  - "All popover UX timing values flow through PopoverUXTiming constants (0.075, 0.15, 1.5)"
  - "Manual runtime checkpoint required for animation perception and accessibility preference behavior"
requirements-completed: [POPOV-04, POPOV-05, ANIM-01, ANIM-02, ANIM-03]
duration: 25min
completed: 2026-03-19
---

# Phase 06 Plan 02: Popover Transition Policy Summary

**Popover transitions now use explicit near-instant fades and a 150ms reduce-motion-aware content switch, with finalize encoding hardened for low-rate mono audio.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-03-19T16:51:53Z
- **Completed:** 2026-03-19T17:16:30Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Added centralized animation timing contracts in `PopoverUXTiming` and wired them into popover content and presentation paths.
- Implemented reduce-motion-aware finalize transition policy and explicit popover show/close fade handling.
- Completed automated + manual checkpoint verification, including runtime finalize save bug fix validated by user.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Wave 0 timing-policy test scaffolds** - `3ce3a38` (feat)
2. **Task 2: Implement centralized timing constants and transition policy** - `3ce3a38` (feat)
3. **Task 3: Verify near-instant popover behavior and 150ms finalize transition on real runtime** - manual verification approved

Additional runtime correctness fix during checkpoint:

- **Deviation fix:** `b81f550` (fix) — hardened AAC finalize path for low-sample-rate mono input.

## Files Created/Modified
- `EchoRecorder/UI/MenuBar/PopoverUXTiming.swift` - Added policy constants and animation/transition policy helpers.
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` - Added reduce-motion transition branch and 150ms animated content switch.
- `EchoRecorder/UI/MenuBar/StatusItemController.swift` - Applied explicit 75ms show/close fades with default popover animation disabled.
- `EchoRecorderTests/UI/FinalizeTransitionTimingTests.swift` - Added timing and reduce-motion policy assertions.
- `EchoRecorderTests/UI/PopoverAnimationPolicyTests.swift` - Added popover fade policy assertions.
- `EchoRecorderTests/UI/StatusItemControllerIconTests.swift` - Added integration-level policy checks.
- `EchoRecorder/Core/Output/AudioWriterPipeline.swift` - Added adaptive AAC bitrate and fallback writer path.
- `EchoRecorderTests/Output/AudioWriterPipelineTests.swift` - Added regression test for low-rate mono finalize.

## Decisions Made
- Preserved locked motion contract values (0.075/0.15/1.5) with no alternate durations for this flow.
- Treated finalize encoder failure as blocking runtime bug and fixed inline under deviation rules.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Generated Xcode project to include new timing policy files**
- **Found during:** Task 2
- **Issue:** `PopoverUXTiming.swift` was not present in the generated Xcode project, causing test/build targeting issues.
- **Fix:** Ran `xcodegen generate` and re-ran targeted tests.
- **Files modified:** `EchoRecorder.xcodeproj/project.pbxproj`
- **Verification:** Targeted timing/policy tests compiled and passed.
- **Committed in:** `3ce3a38`

**2. [Rule 1 - Bug] Fixed AAC finalize failure on low-rate mono input**
- **Found during:** Task 3 runtime verification
- **Issue:** Finalize save failed with `AudioCodecInitialize failed` / bitrate configuration error.
- **Fix:** Added adaptive bitrate selection by sample-rate/channel and fallback write path without forced bitrate.
- **Files modified:** `EchoRecorder/Core/Output/AudioWriterPipeline.swift`, `EchoRecorderTests/Output/AudioWriterPipelineTests.swift`
- **Verification:** User confirmed runtime save succeeds; regression test added and commit landed.
- **Committed in:** `b81f550`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Deviations were required to complete verification and ensure runtime correctness; no scope creep.

## Issues Encountered

- Runtime finalize failed during human verification until AAC fallback fix was applied.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 06 UX and animation contracts are implemented, validated, and stable for downstream polish or release prep.

## Self-Check: PASSED
