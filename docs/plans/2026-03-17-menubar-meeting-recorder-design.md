# Menu Bar Meeting Recorder Design Spec

Date: 2026-03-17
Platform: macOS (menu bar app)
Primary language: Swift

## 1) Product Goal

Build a persistent macOS menu bar app that makes local recording of meetings simple and reliable.
Users should be able to start recording from the menu bar using a preconfigured profile, monitor live audio levels, adjust levels during recording, stop recording, and then name/save the result with minimal friction.

## 2) Scope

### In Scope (MVP)
- Persistent menu bar app with clear recording status in the menu bar.
- Profile-based recording start (source combinations and default levels).
- Window-based video capture as default (user selects meeting window).
- Audio capture for system audio plus selected microphone source.
- Live meters and gain controls for each active audio source.
- Continuous elapsed-time/status indicator while recording.
- Stop recording and finalize flow (rename + optional save directory override).
- Default save directory in settings.
- Outputs include:
  - `master.mp4` (H.264 video + AAC mixed audio)
  - Isolated audio tracks (system/mic) as sidecar files.

### Out of Scope (MVP)
- Cloud sync/transcription.
- Advanced timeline editing.
- Team collaboration/sharing.
- Noise removal/post-processing beyond basic level controls.

## 3) User Personas and Success Criteria

### Primary user
- Individual creator/knowledge worker recording Zoom/Meet/Teams calls locally.

### Success criteria
- User can start recording in <= 2 clicks after setup.
- User can see live source levels and adjust gain during recording.
- User always knows whether recording is active.
- Recording finalize/save succeeds reliably, with recovery path on failure.

## 4) User Experience and Interaction Flow

### A) First run
1. Launch app from Applications.
2. Guided setup wizard checks and requests permissions:
   - Screen Recording (required for window capture/system audio capture path)
   - Microphone (required when profile includes mic)
   - Camera (required only if profile includes camera)
3. Wizard validates at least one usable profile and default save directory.
4. User lands in menu bar idle state.

### B) Idle menu state
- Menu shows:
  - Start Recording (last-used profile)
  - Choose Profile
  - Profiles...
  - Default Save Directory...
  - Preferences
  - Quit

### C) Recording state
1. User clicks `Start Recording`.
2. App transitions: `idle -> preparing -> recording`.
3. Menu bar icon switches to active state (red indicator + elapsed time).
4. Popover displays:
   - Source list (System, Mic, optional camera mic)
   - Live meter (RMS + peak)
   - Gain slider per source
   - Mute toggle per source
   - Clip/too-low warnings
   - Stop Recording button

### D) Stop and finalize
1. User clicks `Stop Recording`.
2. App transitions: `recording -> stopping -> finalizing`.
3. File writer finalizes outputs and manifest.
4. Save prompt:
   - Recording name field
   - Optional directory override
   - Option to keep default directory unchanged
5. If user confirms defaults, app auto-saves with timestamped filename.
6. App returns to `idle`.

## 5) Functional Requirements

### Recording and Profiles
- FR-001: App supports multiple user-defined recording profiles.
- FR-002: A profile defines source selection and gain defaults.
- FR-003: App starts recording using selected profile without opening a full window.
- FR-004: Default capture target is user-selected meeting window.

### Live Monitoring and Controls
- FR-005: App displays independent live meters for each active source.
- FR-006: App supports per-source gain adjustment during recording.
- FR-007: App supports per-source mute during recording.
- FR-008: Meter refresh interval target is 50 ms.

### Status and Lifecycle
- FR-009: Menu bar icon continuously reflects recording status.
- FR-010: Elapsed recording time is visible during active recording.
- FR-011: App provides explicit state transitions and prevents invalid actions.

### Output and Save Flow
- FR-012: App writes `master.mp4` (H.264 + AAC mixed track).
- FR-013: App writes isolated source tracks (`system_audio`, `mic_audio`) as sidecars.
- FR-014: User can rename recording post-stop before finalize completes.
- FR-015: User can override save directory at finalize, or use default.

### Reliability
- FR-016: If a source disconnects, recording continues with remaining sources and warning.
- FR-017: If selected window disappears, app warns and allows continue/stop behavior.
- FR-018: App checks disk-space threshold before and during recording.
- FR-019: Crash/interruption leaves recoverable temp assets.
- FR-020: On next launch, app offers recovery for incomplete sessions.

## 6) Non-Functional Requirements

- NFR-001: Startup to idle menu availability <= 2 s on supported machines.
- NFR-002: Metering/control interactions should feel immediate (< 100 ms UI latency).
- NFR-003: Long recordings (>= 2 h) should complete without drift-induced failure under normal resource conditions.
- NFR-004: Finalize failures must preserve raw assets and produce actionable error text.

## 7) Technical Architecture

Core modules:
- `MenuBarUI`: `NSStatusItem` + `NSPopover`, state-bound controls.
- `RecorderCoordinator`: finite-state machine and orchestration.
- `PermissionManager`: setup wizard and permission health checks.
- `CaptureService`: window/system capture using `ScreenCaptureKit`.
- `MicCaptureService`: mic stream capture via `AVAudioEngine`/Core Audio.
- `AudioMixerService`: gain, mute, mixed bus generation.
- `MeteringService`: RMS + peak stats emitted at fixed cadence.
- `FileWriterService`: mux mixed master output + sidecar isolated tracks.
- `RecordingLibrary`: metadata manifests and recovery indexing.

Design constraints:
- Use protocol-first boundaries for core services to enable unit tests without device access.
- Keep capture and encode on background queues; keep UI on main thread.
- Persist profile/settings/manifest in `Application Support`.

## 8) Data Model (Persisted)

### `Profile`
- `id: UUID`
- `name: String`
- `videoTarget: selectedWindow`
- `includeSystemAudio: Bool`
- `micDeviceID: String?`
- `cameraDeviceID: String?`
- `sourceDefaults: [SourceGainConfig]`
- `outputPreset: mp4H264Aac`

### `AppSettings`
- `defaultSaveDirectory: String`
- `filenameTemplate: String`
- `lastUsedProfileID: UUID?`
- `autoRevealInFinder: Bool`
- `minFreeDiskGB: Int`

### `RecordingManifest`
- `recordingID: UUID`
- `startedAt`, `endedAt`
- `profileSnapshot`
- `outputPaths`
- `durationSeconds`
- `finalizationStatus`
- `errorFlags`

Output folder example:
- `<name>/master.mp4`
- `<name>/system_audio.m4a`
- `<name>/mic_audio.m4a`
- `<name>/manifest.json`

## 9) Error Handling and Recovery Policy

- Missing permission: block start; show exact requirement; deep-link to System Settings.
- Source disconnect: continue recording remaining active sources; badge warning in UI.
- Window lost: continue audio if possible; mark video interruption in manifest.
- Low disk: warn early; auto-stop gracefully if threshold crossed.
- Finalization error: retain temporary media; expose `Recover Last Recording`.
- Crash/unexpected quit: launch-time scan for incomplete sessions and recovery options.

## 10) Testing Strategy

- Unit tests for:
  - State machine transitions in `RecorderCoordinator`
  - Profile/settings persistence
  - Meter normalization and clipping thresholds
  - Finalization path decisions
- Integration tests for:
  - Start/stop orchestration with mocked capture services
  - Manifest correctness
- Manual matrix:
  - Zoom/Meet/Teams window capture
  - Built-in mic + external USB mic
  - Permission revoke/regrant flows
  - Sleep/wake mid-recording
  - Low-disk behavior

## 11) Milestones

1. Foundation (app shell, state model, persistence)
2. Setup wizard + profile management
3. Capture pipeline (window/system/mic)
4. Live metering and gain controls
5. Finalization + save UX
6. Recovery/hardening + beta packaging

## 12) Open Questions for Post-MVP

- Should camera video compositing be included in V1.1?
- Should isolated tracks use `m4a` or `wav` by default?
- Should app auto-open saved recording in Finder or QuickTime?
