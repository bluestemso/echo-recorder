# EchoRecorder — Roadmap (v2.0)

## Overview

**6 phases** | **21 active requirements mapped** | All v2.0 requirements covered ✓

---

## Phase 01: Live Level Monitoring

**Goal:** Add live, per-source audio level feedback during recording.

**Requirements:** METER-01, METER-02, METER-03, METER-04 (legacy baseline)

**Plans:** 1/1 plans complete

Plans:
- [x] 01-PLAN.md — Wire recorder sample callbacks to metering UI with animated level bars

**Success criteria:**
1. System and mic levels are visible in the recording popover
2. Level bars update in near real time from incoming audio buffers
3. Visual metering uses clear low/medium/high color states

---

## Phase 02: Per-Source Gain Control

**Goal:** Let users adjust mic and system gain independently from the popover.

**Requirements:** GAIN-01, GAIN-02, GAIN-03 (legacy baseline)

**Plans:** 1/1 plans complete

Plans:
- [x] 02-PLAN.md — Add per-source slider controls and bind them to recording gain state

**Success criteria:**
1. Each source row exposes a gain slider
2. Slider updates are reflected immediately in displayed levels
3. Gain values remain in sync with recorder/view-model state

---

## Phase 03: Save Location Picker

**Goal:** Add finalize-time save location selection with persisted default directory.

**Requirements:** SAVE-01, SAVE-02, SAVE-03 (legacy baseline)

**Plans:** 1/1 plans complete

Plans:
- [x] 03-PLAN.md — Add save location persistence + finalize flow directory picker

**Success criteria:**
1. User can choose save directory before finalizing
2. If no override is chosen, app uses persisted default directory
3. Default save directory persists across launches

---

## Phase 04: Input Source Selection

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

## Phase 05: Menu Bar Iconography & Recording Indicator

**Goal:** Use SF Symbols for menu bar icons and add red background indicator during recording.

**Requirements:** ICON-01, ICON-02, ICON-03, ICON-04, IND-01, IND-02, IND-03

**Plans:** 2/2 plans complete

Plans:
- [x] 05-01-PLAN.md — Define and test `RecorderState -> StatusItemVisualState` mapping contract for iconography and recording-only red-pill semantics
- [x] 05-02-PLAN.md — Wire state-driven icon/pill rendering in `StatusItemController`, add latency + appearance tests, and run manual visibility checkpoint

**Success criteria:**
1. Menu bar icon shows `waveform` or `mic.fill` when idle
2. Menu bar icon shows `record.circle.fill` (red) when recording
3. Icon updates within 100ms of state change
4. Menu bar shows red background/border when recording is active
5. Red indicator is clearly visible against any desktop wallpaper
6. Indicator is removed when recording stops

---

## Phase 06: Popover UX Improvements

**Goal:** Improve popover design (especially post-recording view) and speed up animations.

**Requirements:** POPOV-01, POPOV-02, POPOV-03, POPOV-04, POPOV-05, ANIM-01, ANIM-02, ANIM-03

**Plans:** 2/2 plans complete

Plans:
- [x] 06-01-PLAN.md — Finalize-first UX state contract (editable name, action hierarchy, saving/success feedback)
- [x] 06-02-PLAN.md — Transition timing + popover animation policy (150ms content, near-instant show/close, reduce-motion fallback)

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
| INPUT-01 | Phase 04 |
| INPUT-02 | Phase 04 |
| INPUT-03 | Phase 04 |
| INPUT-04 | Phase 04 |
| INPUT-05 | Phase 04 |
| INPUT-06 | Phase 04 |
| ICON-01 | Phase 05 |
| ICON-02 | Phase 05 |
| ICON-03 | Phase 05 |
| ICON-04 | Phase 05 |
| IND-01 | Phase 05 |
| IND-02 | Phase 05 |
| IND-03 | Phase 05 |
| POPOV-01 | Phase 06 |
| POPOV-02 | Phase 06 |
| POPOV-03 | Phase 06 |
| POPOV-04 | Phase 06 |
| POPOV-05 | Phase 06 |
| ANIM-01 | Phase 06 |
| ANIM-02 | Phase 06 |
| ANIM-03 | Phase 06 |
