# EchoRecorder — Requirements

## v1 Requirements (Phase 3 Milestone)

### Live Metering (METER)
- [ ] **METER-01**: User can see a live RMS/peak level bar for the system audio source while recording
- [ ] **METER-02**: User can see a live RMS/peak level bar for the microphone source while recording
- [ ] **METER-03**: Level bars are color-coded: green (safe), yellow (loud), red (clipping)
- [ ] **METER-04**: Meters update at approximately 50ms intervals (≤ 20fps refresh)

### Gain Control (GAIN)
- [ ] **GAIN-01**: User can adjust the gain of the system audio source via a per-source slider in the recording popover
- [ ] **GAIN-02**: User can adjust the gain of the microphone source via a per-source slider in the recording popover
- [ ] **GAIN-03**: Changing a gain slider visibly affects the corresponding live meter in real-time

### Save Location (SAVE)
- [ ] **SAVE-01**: User can choose an output directory during the finalize step before the recording is saved
- [ ] **SAVE-02**: If the user does not choose a directory, the recording saves to the configured default save directory
- [ ] **SAVE-03**: The default save directory is configurable and persisted across app launches

---

## v2 Requirements (Deferred)

- Peak hold indicator on meter bars — nice UX polish, low priority for MVP
- Numerical dBFS readout alongside meter bars — power user feature, deferred
- Mute toggle per source — mentioned in design doc, deferred post-MVP
- Clip/too-low warning badge UI — deferred until metering is stable
- Per-profile gain defaults — user-defined profiles with stored gain presets

---

## Out of Scope

- Stereo L/R channel split meters — sources are mono-summed; unnecessary complexity
- LUFS / integrated loudness metering — overkill for meeting recording context
- Post-processing effects or noise removal — out of scope for this app
- Video capture — explicitly deferred to future milestone
- Cloud sync / transcription — out of scope, local-only tool

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| METER-01 | Phase 1 | Pending |
| METER-02 | Phase 1 | Pending |
| METER-03 | Phase 1 | Pending |
| METER-04 | Phase 1 | Pending |
| GAIN-01 | Phase 2 | Pending |
| GAIN-02 | Phase 2 | Pending |
| GAIN-03 | Phase 2 | Pending |
| SAVE-01 | Phase 3 | Pending |
| SAVE-02 | Phase 3 | Pending |
| SAVE-03 | Phase 3 | Pending |
