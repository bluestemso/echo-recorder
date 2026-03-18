# Research: Pitfalls

## Pitfall 1: Updating @Published from the Audio Thread
**Risk:** `MeteringService` runs its tap block on a real-time audio thread. Directly writing a `@Published` property from outside `@MainActor` is a Swift 6 data race and a practical crash in earlier versions.

**Prevention:**
- Always dispatch meter updates to `DispatchQueue.main.async { }` before setting `@Published` properties
- OR use `AsyncStream` + `MainActor` consumption pattern
- **Phase impact:** Metering integration phase must explicitly handle this dispatch; unit tests should verify no main-thread violations

---

## Pitfall 2: Timer Accumulating After Recording Stops
**Risk:** If the `Timer.publish` used to drive meter refresh is not cancelled when recording ends, it continues firing, causing zombie UI updates and possible retain cycles.

**Prevention:**
- Store `AnyCancellable` for the timer in `RecordingViewModel`
- Cancel it in an `onStop()` or `deinit` path
- Test: verify `levelRows` stop updating after `stopRecording()` is called

---

## Pitfall 3: Gain Slider Causing Audio Engine Reconfiguration
**Risk:** Plugging gain sliders directly into an `AVAudioMixerNode.outputVolume` is safe. But if someone mistakenly reconfigures the audio graph mid-stream (e.g., reconnecting nodes), `AVAudioEngine` will throw and the recording stops.

**Prevention:**
- Gain control should only modify `outputVolume` on a mixer node — never reconfigure the node graph during recording
- The existing `AudioMixerService` already applies gain in-buffer before passing samples onward; keep this approach rather than inserting a graph-level node

---

## Pitfall 4: NSOpenPanel Blocking Main Thread (runModal)
**Risk:** `NSOpenPanel.runModal()` blocks the main thread. While this is the documented AppKit pattern, calling it inside a `Task` or `async` context without care can cause deadlocks.

**Prevention:**
- Call `panel.runModal()` from a synchronous button action (not inside `await`)
- Wrap in a helper function called from SwiftUI's `.onReceive` or `Button { }` directly
- Test: directory picker should not hang app during recording state

---

## Pitfall 5: Save Directory URL Without Security-Scoped Bookmark
**Risk:** On a sandboxed macOS app, URLs obtained from `NSOpenPanel` are only valid in the current session. If the app is sandboxed and the user picks a directory, a future launch won't have access if the URL isn't bookmarked.

**Prevention:**
- This app currently has `CODE_SIGNING_ALLOWED: NO` and is not sandboxed (from `project.yml`)
- No sandbox bookmark required for current state
- **If sandbox is added later:** must implement security-scoped bookmarks before release

---

## Pitfall 6: FinalizedAudioOutput Directory vs. Override Directory Confusion
**Risk:** The current finalizer accepts `overrideDirectory: URL?` but defaults to `FileManager.default.temporaryDirectory`. If `AppSettings.defaultSaveDirectory` isn't plumbed in, recordings always land in `/tmp`, confusing users.

**Prevention:**
- Wire `AppSettings.defaultSaveDirectory` to `RecordingFinalizer`'s default directory at initialization
- The save location picker populates `overrideDirectory` only when the user explicitly changes the default
