# Phase 3: Save Location Picker - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning
**Source:** Codebase audit

<domain>
## Phase Boundary

At finalize time, show the user the current save directory with a "Change Location" button. Clicking it opens an NSOpenPanel directory picker. The chosen directory is used for the recording output. The default save directory is persisted via JSONStore and survives app restarts.

</domain>

<decisions>
## Implementation Decisions

### Persistence Layer
- Store default save directory as a bookmark-safe path string in JSONStore with key `"defaultSaveDirectory"`
- `JSONStore` already exists in `Core/Persistence/` — use it directly, do NOT add UserDefaults
- A new `SaveLocationService` struct wraps JSONStore for save-directory read/write

### Directory Picker
- Use `NSOpenPanel` (not NSSavePanel) with `canChooseDirectories = true`, `canChooseFiles = false`, `allowsMultipleSelection = false`
- Trigger from `FinalizeRecordingViewModel.chooseDirectory()` → call site is `@MainActor`

### FinalizeRecordingViewModel Updates
- Add `@Published var selectedDirectory: URL` — initialized from `SaveLocationService.load()`, falls back to defaults Downloads
- Add `func chooseDirectory()` — opens NSOpenPanel, updates `selectedDirectory`, saves to `SaveLocationService`
- `finalizeRecording(fileName:)` now resolves to `selectedDirectory` instead of requiring caller to pass `overrideDirectory`

### FinalizeView (new SwiftUI view)
- Shows: current directory path (truncated), "Change Location" button, recording name text field, "Save Recording" button
- Displayed as a sheet from `RecordingPopoverView` when `viewModel.isShowingFinalizeSheet == true`

### RecordingViewModel Wiring
- After `stopAndFinalize()` succeeds, set `isShowingFinalizeSheet = true` on a `FinalizeRecordingViewModel`
- But wait — the flow is: user clicks Stop → coordinator runs `stopAndFinalize` internally → output is stored
- Simpler approach per current architecture: add a `@Published var showFinalizePrompt = false` and `pendingFinalizeOutput: FinalizedAudioOutput?` to `RecordingViewModel`. After stop, set both. `RecordingPopoverView` shows a mini finalize section (not a modal sheet, which is harder with NSPopover).

### Claude's Discretion
- Layout: inline expansion below the Stop button (no modal sheet — NSPopover doesn't support `.sheet` well)
- Recording name: use the auto-generated name from `recordingNameProvider`; show it read-only in the finalize section
- After user clicks "Save Recording", clear the finalize prompt

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Key Files
- `EchoRecorder/Core/Persistence/JSONStore.swift` — Generic Codable key/value store
- `EchoRecorder/Core/Output/RecordingFinalizer.swift` — `overrideDirectory` / `defaultDirectory` pattern, `FinalizedAudioOutput`
- `EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift` — Existing VM to expand
- `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` — Where to wire the finalize → stop flow  
- `EchoRecorder/UI/MenuBar/RecordingPopoverView.swift` — Where UI changes land
- `EchoRecorder/UI/MenuBar/StatusItemController.swift` — How RecordingViewModel is composed (no wiring here needed)
- `EchoRecorder/App/AppDelegate.swift` — How StatusItemController is initialized

### Tests to Read First
- `EchoRecorderTests/Output/FinalizeRecordingViewModelTests.swift` — Existing tests to keep passing
- `EchoRecorderTests/UI/RecordingViewModelTests.swift` — Existing ViewModel tests

### Project Structure
- `.planning/codebase/STRUCTURE.md` — Overall directory layout

</canonical_refs>

<specifics>
## Specific Ideas

- `RecordingFinalizer` already accepts `overrideDirectory: URL?` — pass `selectedDirectory` from `FinalizeRecordingViewModel`
- `JSONStore` uses `save<Encodable>(_:as:)` and `load<Decodable>(_:from:)` — store the path as `String` (bookmark bookmarks add complexity, plain path string is fine for MVP)
- `NSOpenPanel` on macOS requires dialog to run on main thread — already `@MainActor` in ViewModel
- xcodegen required if any new `.swift` files are added — use `xcodegen generate` after creating new files

</specifics>

<deferred>
## Deferred Ideas

- Security-scoped bookmarks for sandbox access (overkill for current local-mac app)
- Settings panel in a separate window for configuring save dir independently of finalize flow
- Showing finalize in a separate window (deferred — NSPopover sheet limitations)

</deferred>

---

*Phase: 03-save-location-picker*
*Context gathered: 2026-03-18 via codebase audit*
