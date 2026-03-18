# Phase 3: Save Location Picker — Summary

**Completed:** 2026-03-18

## Goal

User can choose where recordings are saved at finalize time, and a default save location is persisted across launches.

## Requirements Satisfied

| REQ-ID | Requirement | Status |
|--------|-------------|--------|
| SAVE-01 | User can choose an output directory during the finalize step before the recording is saved | ✅ Complete |
| SAVE-02 | If the user does not choose a directory, the recording saves to the configured default save directory | ✅ Complete |
| SAVE-03 | The default save directory is configurable and persisted across app launches | ✅ Complete |

## What Was Built

1. **SaveLocationService** — Persistence layer for default save directory with JSONStore backend
2. **RecorderCoordinator updates** — Added `stopCapture()` and `finalizeRecording()` methods for two-step stop flow
3. **FinalizeRecordingViewModel** — Expanded to own directory picker state and NSOpenPanel integration
4. **FinalizeView** — SwiftUI UI showing target directory with "Change Location" and "Save" buttons
5. **RecordingViewModel wiring** — Wired the two-step stop flow with `pendingFinalize` state

## Test Results

- SaveLocationServiceTests: 2 tests pass
- FinalizeRecordingViewModelTests: 4 tests pass
- RecordingViewModelTests: 1 new test (`testPendingFinalizeIsNilInitially`)
- Total: 82 tests pass, 0 failures

## Key Decisions

- Used two-step stop flow (stopCapture → pendingFinalize → finalizeRecording) to allow directory selection before file write
- Persisted save location via JSONStore in Application Support directory
- Default fallback to Downloads directory when nothing persisted

## Issues Resolved

- Phase 3 implementation complete but not formally closed — now summarized

## Technical Debt

None identified for this phase.

---

*Phase 3 complete — v1.0 MVP fully shipped*