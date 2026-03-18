# Phase 2: Per-Source Gain Control - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning
**Source:** Codebase audit

<domain>
## Phase Boundary

Add per-source gain sliders to the recording popover (one for system audio, one for microphone). The gain pipeline backend is fully implemented. This phase is UI only.

</domain>

<decisions>
## Implementation Decisions

### Gain Slider Range
- Slider range: `0.0...2.0` (0 = mute, 1 = unity, 2 = 2× boost)
- This matches the existing `SourceGain` model which is unconstrained

### UI Layout
- Each source row in `RecordingPopoverView`: label → meter bar → gain slider (below meter)
- Slider is always visible when recording is active (same context as the meter bar)
- Label above slider: "Gain" (caption weight, secondary color)

### ViewModel Exposure
- Add `@Published private(set) var gainValues: [InputSource: Float]` initialized to `[.system: 1.0, .microphone: 1.0]`
- `setGain(_:for:)` already sets `sourceGain` — also update `gainValues` to keep slider in sync
- The SwiftUI slider binds via `.init(get: { viewModel.gainValues[row.source] ?? 1.0 }, set: { viewModel.setGain($0, for: row.source) })`

### Claude's Discretion
- Whether slider resets to 1.0 when recording stops — lean toward keeping last value (friendlier UX)
- Exact slider step value — leave continuous (default SwiftUI Slider)
- No tick marks or numerical readout (deferred to v2 per REQUIREMENTS.md)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Gain Pipeline
- `EchoRecorder/Core/Audio/AudioMixerService.swift` — `SourceGain` struct, `applyGain()` protocol
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` — `setGain(_:for:)`, `sourceGain` private state
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` — Current popover layout (no slider yet)
- `EchoRecorder/UI/MenuBar/LevelMeterView.swift` — Meter bar component to sit alongside slider

### Tests
- `EchoRecorderTests/UI/RecordingViewModelTests.swift` — 7 existing tests to extend
- `EchoRecorderTests/Audio/AudioGainPipelineTests.swift` — Backend gain test

### Phase 1 Summary
- `.planning/phases/01-live-level-monitoring/01-SUMMARY.md` — What was built in Phase 1

</canonical_refs>

<specifics>
## Specific Ideas

- The Phase 2 doc at `docs/plans/2026-03-17-menubar-meeting-recorder-phase2-audio-first-plan.md` Task 5 gives the original gain pipeline spec — all backend parts are done
- Phase 1 SUMMARY confirms: `LevelMeterView.swift`, meter dispatch pipeline, gain scaling all complete
- xcodegen is needed if any new files are added to the project

</specifics>

<deferred>
## Deferred Ideas

- Numerical dBFS readout alongside slider (REQUIREMENTS.md v2 list)
- Mute toggle per source (REQUIREMENTS.md v2 list)
- Peak hold on meter bars (REQUIREMENTS.md v2 list)

</deferred>

---

*Phase: 02-per-source-gain-control*
*Context gathered: 2026-03-18 via codebase audit*
