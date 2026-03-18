# EchoRecorder

## What This Is

EchoRecorder is a macOS menu bar app for local recording of meetings and calls. It captures system audio and microphone input simultaneously, produces mixed and isolated audio tracks, and is designed for individual knowledge workers who want lightweight, reliable local recording without cloud dependency.

## Core Value

User can start a recording in two clicks, monitor and adjust levels live, and reliably get named, organized output files when they stop.

## Requirements

### Validated

<!-- v1.0 MVP shipped -->

- ✓ Menu bar app shell (`LSUIElement`) with popover-based recording UI — v1.0
- ✓ Recording state machine (`idle → preparing → recording → finalizing → idle`) — v1.0
- ✓ Microphone permission request flow — v1.0
- ✓ Screen recording permission request flow — v1.0
- ✓ System audio capture via ScreenCaptureKit — v1.0
- ✓ Microphone capture via AVAudioEngine tap — v1.0
- ✓ Per-source gain model and UI bindings (system audio, microphone) — v1.0
- ✓ Audio writer pipeline: `mixed.m4a`, `system_audio.m4a`, `mic_audio.m4a` — v1.0
- ✓ Output filename validation and finalizer flow — v1.0
- ✓ JSON persistence and crash-recovery manifest scanning — v1.0
- ✓ Unit, integration, and smoke harness test coverage — v1.0
- ✓ Live input level monitoring UI (real-time RMS/peak meters displayed in recording popover per source) — v1.0
- ✓ Per-source gain adjustment controls in recording popover (sliders visible during recording) — v1.0
- ✓ Save location picker during finalize step (directory override before saving output) — v1.0

### Active

<!-- Next milestone scope to be defined with /gsd-new-milestone -->

(TBD — start next milestone with `/gsd-new-milestone`)

### Out of Scope

- Video capture/muxing — intentionally deferred; audio-first MVP must ship and stabilize first
- Cloud sync / transcription — out of scope; adds backend complexity not aligned with local-first goals
- Noise removal or post-processing beyond level controls — out of scope for MVP
- Multi-machine or team collaboration — out of scope; single-user local tool

## Current State

**Shipped:** v1.0 MVP — 3 phases, 10 requirements, 82 tests passing

**Tech Stack:** Swift / SwiftUI + AppKit / AVFoundation / ScreenCaptureKit / Combine
**Platform:** macOS 14.0+
**Build System:** XcodeGen

## Next Milestone Goals

To be defined with `/gsd-new-milestone` — questioning → research → requirements → roadmap

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
| Save location picker at finalize step | Lower friction during recording; decision deferred until user confirms they want to save | ✓ Good — v1.0 shipped |
| Two-step stop flow (stopCapture → finalize) | Allows directory selection before file write | ✓ Good — v1.0 shipped |

---
*Last updated: 2026-03-18 after v1.0 MVP milestone*