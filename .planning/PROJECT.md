# EchoRecorder

## What This Is

EchoRecorder is a macOS menu bar app for local recording of meetings and calls. It captures system audio and microphone input simultaneously, producing mixed and isolated audio tracks, and is designed for individual knowledge workers who want lightweight, reliable local recording without cloud dependency.

## Core Value

User can start a recording in two clicks, monitor and adjust levels live, and reliably get named, organized output files when they stop.

## Requirements

### Validated

<!-- Shipped and confirmed valuable in Phase 2 audio-first MVP. -->

- ✓ Menu bar app shell (`LSUIElement`) with popover-based recording UI — Phase 2
- ✓ Recording state machine (`idle → preparing → recording → finalizing → idle`) — Phase 2
- ✓ Microphone permission request flow — Phase 2
- ✓ Screen recording permission request flow — Phase 2
- ✓ System audio capture via ScreenCaptureKit — Phase 2
- ✓ Microphone capture via AVAudioEngine tap — Phase 2
- ✓ Per-source gain model and UI bindings (system audio, microphone) — Phase 2
- ✓ Audio writer pipeline: `mixed.m4a`, `system_audio.m4a`, `mic_audio.m4a` — Phase 2
- ✓ Output filename validation and finalizer flow — Phase 2
- ✓ JSON persistence and crash-recovery manifest scanning — Phase 2
- ✓ Unit, integration, and smoke harness test coverage — Phase 2

### Active

<!-- Current scope: polish and complete MVP UX. -->

- [ ] Live input level monitoring UI (real-time RMS/peak meters displayed in recording popover per source)
- [ ] Per-source gain adjustment controls in recording popover (sliders visible during recording)
- [ ] Save location picker during finalize step (directory override before saving output)

### Out of Scope

- Video capture/muxing — intentionally deferred; audio-first MVP must ship and stabilize first
- Cloud sync / transcription — out of scope; adds backend complexity not aligned with local-first goals
- Noise removal or post-processing beyond level controls — out of scope for MVP
- Multi-machine or team collaboration — out of scope; single-user local tool

## Context

- **Existing state:** Phase 2 audio-first MVP is complete and tested. The core services (capture, mixing, metering, finalization, recovery) are implemented and covered by unit, integration, and smoke tests.
- **Architecture:** Protocol-first, dependency-injected service layer. Coordinator pattern (`RecorderCoordinator`). AppKit `NSStatusItem` + SwiftUI popover UI. Combine `@Published` state binding.
- **Known gap:** The live metering and gain controls exist in the core (`MeteringService`, `AudioMixerService`, `RecordingViewModel`) but are not fully surfaced or interactive in the UI yet. The save location field in the finalize dialog is also pending.
- **Testing approach:** TDD-first with XCTest. New features should follow the same red/green/commit cycle established in Phase 2.

## Constraints

- **Tech Stack**: Swift / SwiftUI + AppKit / AVFoundation / ScreenCaptureKit / Combine — no new frameworks without strong justification
- **Platform**: macOS 14.0+ only
- **Build system**: XcodeGen (`project.yml` is source of truth; do not edit `.xcodeproj` directly)
- **No video this milestone**: Video capture and muxing is explicitly deferred

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Audio-first MVP (no video) | Reduces complexity; validates core recording loop before adding screen capture | ✓ Good — Phase 2 shipped cleanly |
| SCKit for system audio (audio-only path) | Avoids window capture permissions complexity for audio-only use case | ✓ Good |
| AVAudioEngine for mic | Established Apple API with stable tap interface; supports protocol injection for tests | ✓ Good |
| Buffer-in-memory before write | Simple; sufficient for typical meeting lengths | — Pending (monitor for long recording sessions) |
| Save location picker at finalize step | Lower friction during recording; decision deferred until user confirms they want to save | — Pending |

---
*Last updated: 2026-03-18 after Phase 2 completion and project initialization*
