# EchoRecorder — Roadmap (v2.0)

## Overview

**3 phases** | **19 requirements mapped** | All v2.0 requirements covered ✓

---

## Phase 4: Input Source Selection

**Goal:** Fix Bluetooth microphone issue by adding input source selection with fallback to built-in microphone.

**Requirements:** INPUT-01, INPUT-02, INPUT-03, INPUT-04, INPUT-05, INPUT-06

**Plans:** 2/2 plans complete

Plans:
- [x] 04-01-PLAN.md — Backend: device enumeration, MicCaptureEngine protocol extension, InputDeviceService persistence, RecorderCoordinator wiring
- [x] 04-02-PLAN.md — UI: InputDevicePicker component, inline settings section in RecordingPopoverView

**Success criteria:**
1. User can see available audio input devices in the app
2. User can select which input device to use for recording
3. App defaults to built-in microphone when no selection is made
4. App correctly identifies built-in microphone by device name ("Built-in", "MacBook", "Internal Microphone")
5. Selected device persists across app restarts
6. Recording works when Bluetooth headphones are connected (fixes current bug)

---

## Phase 5: Menu Bar Iconography & Recording Indicator

**Goal:** Use SF Symbols for menu bar icons and add red background indicator during recording.

**Requirements:** ICON-01, ICON-02, ICON-03, ICON-04, IND-01, IND-02, IND-03

**Plans:** 2 plans

Plans:
- [ ] 05-01-PLAN.md — Define and test `RecorderState -> StatusItemVisualState` mapping contract for iconography and recording-only red-pill semantics
- [ ] 05-02-PLAN.md — Wire state-driven icon/pill rendering in `StatusItemController`, add latency + appearance tests, and run manual visibility checkpoint

**Success criteria:**
1. Menu bar icon shows `waveform` or `mic.fill` when idle
2. Menu bar icon shows `record.circle.fill` (red) when recording
3. Icon updates within 100ms of state change
4. Menu bar shows red background/border when recording is active
5. Red indicator is clearly visible against any desktop wallpaper
6. Indicator is removed when recording stops

---

## Phase 6: Popover UX Improvements

**Goal:** Improve popover design (especially post-recording view) and speed up animations.

**Requirements:** POPOV-01, POPOV-02, POPOV-03, POPOV-04, POPOV-05, ANIM-01, ANIM-02, ANIM-03

**Success criteria:**
1. FinalizeView has larger, clearer action buttons
2. FinalizeView shows progress indicator during save operation
3. FinalizeView shows success feedback after recording is saved
4. Smooth transition from recording view to finalize view (within 200ms)
5. Popover appears instantly (no fade-in)
6. Popover disappears instantly (no fade-out)
7. Content transitions animate at 150ms duration

---

## Requirement Traceability

| REQ-ID | Phase |
|--------|-------|
| INPUT-01 | Phase 4 |
| INPUT-02 | Phase 4 |
| INPUT-03 | Phase 4 |
| INPUT-04 | Phase 4 |
| INPUT-05 | Phase 4 |
| INPUT-06 | Phase 4 |
| ICON-01 | Phase 5 |
| ICON-02 | Phase 5 |
| ICON-03 | Phase 5 |
| ICON-04 | Phase 5 |
| IND-01 | Phase 5 |
| IND-02 | Phase 5 |
| IND-03 | Phase 5 |
| POPOV-01 | Phase 6 |
| POPOV-02 | Phase 6 |
| POPOV-03 | Phase 6 |
| POPOV-04 | Phase 6 |
| POPOV-05 | Phase 6 |
| ANIM-01 | Phase 6 |
| ANIM-02 | Phase 6 |
| ANIM-03 | Phase 6 |
