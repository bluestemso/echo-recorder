# Requirements: EchoRecorder

**Defined:** 2026-03-18
**Core Value:** User can start a recording in two clicks, monitor and adjust levels live, and reliably get named, organized output files when they stop.

## v1 Requirements (v2.0 Milestone)

### Iconography (ICON)

- [x] **ICON-01**: Menu bar icon shows SF Symbol `waveform` or `mic.fill` when idle
- [x] **ICON-02**: Menu bar icon shows SF Symbol `record.circle.fill` (red) when recording
- [x] **ICON-03**: Menu bar icon changes based on recorder state (idle → preparing → recording → finalizing → idle)
- [x] **ICON-04**: Icon update occurs within 100ms of state change

### Recording Indicator (IND)

- [x] **IND-01**: Menu bar status item shows red background/border when recording is active
- [x] **IND-02**: Red indicator is clearly visible against any desktop wallpaper
- [x] **IND-03**: Indicator is removed when recording stops

### Popover Design (POPOV)

- [x] **POPOV-01**: FinalizeView shows larger, clearer action buttons
- [x] **POPOV-02**: FinalizeView shows progress indicator during save operation
- [x] **POPOV-03**: FinalizeView shows success feedback after recording is saved
- [x] **POPOV-04**: Smooth transition from recording view to finalize view
- [x] **POPOV-05**: Popover content transitions complete within 200ms

### Animation Speed (ANIM)

- [x] **ANIM-01**: Popover appears instantly (no fade-in animation)
- [x] **ANIM-02**: Popover disappears instantly (no fade-out animation)
- [x] **ANIM-03**: Content transitions animate at 150ms duration

### Input Source (INPUT)

- [x] **INPUT-01**: App displays available audio input devices in settings or recording UI
- [x] **INPUT-02**: User can select which audio input device to use for recording
- [x] **INPUT-03**: App defaults to built-in microphone when no device is manually selected
- [x] **INPUT-04**: App detects built-in microphone by checking device name for "Built-in", "MacBook", or "Internal Microphone"
- [x] **INPUT-05**: Input device selection persists across app launches
- [x] **INPUT-06**: App records microphone audio when Bluetooth headphones are connected (fix current bug)

## v2 Requirements (Deferred)

- Peak hold indicator on meter bars
- Numerical dBFS readout alongside meter bars
- Mute toggle per source
- Clip/too-low warning badge UI

## Out of Scope

| Feature | Reason |
|---------|--------|
| Video recording | Explicitly deferred to future milestone |
| Cloud sync / transcription | Out of scope, local-only tool |
| Multiple simultaneous input devices | Single input source is sufficient for MVP |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ICON-01 | Phase 4 | Complete |
| ICON-02 | Phase 4 | Complete |
| ICON-03 | Phase 4 | Complete |
| ICON-04 | Phase 4 | Complete |
| IND-01 | Phase 5 | Complete |
| IND-02 | Phase 5 | Complete |
| IND-03 | Phase 5 | Complete |
| POPOV-01 | Phase 6 | Complete |
| POPOV-02 | Phase 6 | Complete |
| POPOV-03 | Phase 6 | Complete |
| POPOV-04 | Phase 6 | Complete |
| POPOV-05 | Phase 6 | Complete |
| ANIM-01 | Phase 6 | Complete |
| ANIM-02 | Phase 6 | Complete |
| ANIM-03 | Phase 6 | Complete |
| INPUT-01 | Phase 4 | Complete |
| INPUT-02 | Phase 4 | Complete |
| INPUT-03 | Phase 4 | Complete |
| INPUT-04 | Phase 4 | Complete |
| INPUT-05 | Phase 4 | Complete |
| INPUT-06 | Phase 4 | Complete |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-18*
*Last updated: 2026-03-18 after v2.0 milestone start*