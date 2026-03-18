# EchoRecorder — Roadmap (Milestone 3)

## Overview
**3 phases** | **10 requirements mapped** | All v1 requirements covered ✓

---

## Phase 1: Live Level Monitoring

**Goal:** User can see real-time audio level meters for system audio and mic sources in the recording popover.

**Requirements:** METER-01, METER-02, METER-03, METER-04

**Success criteria:**
1. Two meter bars (system audio, microphone) are visible in the recording popover during an active recording
2. Meter bars visibly animate at roughly ≤50ms intervals while recording is active
3. Meter bars change color (green/yellow/red) based on signal level
4. Meters are static (zeroed) when recording is not active

---

## Phase 2: Per-Source Gain Control

**Goal:** User can adjust the gain (volume level) of each audio source via sliders while recording, and the live meters reflect the change.

**Requirements:** GAIN-01, GAIN-02, GAIN-03

**Success criteria:**
1. A gain slider is visible for the system audio source row in the recording popover
2. A gain slider is visible for the microphone source row in the recording popover
3. Moving a gain slider causes the corresponding meter bar to visibly change within one refresh cycle

---

## Phase 3: Save Location Picker

**Goal:** User can choose where recordings are saved at finalize time, and a default save location is persisted across launches.

**Requirements:** SAVE-01, SAVE-02, SAVE-03

**Success criteria:**
1. Finalize step shows the current target directory with a "Change Location" button
2. Clicking "Change Location" presents an OS directory picker
3. If no directory is chosen, the recording saves to the app's configured default save directory
4. Default save directory is configurable and survives an app restart

---

## Requirement Traceability

| REQ-ID | Phase |
|--------|-------|
| METER-01 | Phase 1 |
| METER-02 | Phase 1 |
| METER-03 | Phase 1 |
| METER-04 | Phase 1 |
| GAIN-01 | Phase 2 |
| GAIN-02 | Phase 2 |
| GAIN-03 | Phase 2 |
| SAVE-01 | Phase 3 |
| SAVE-02 | Phase 3 |
| SAVE-03 | Phase 3 |
