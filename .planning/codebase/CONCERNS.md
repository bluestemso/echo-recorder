# Concerns & Tech Debt Map

## Technical Debt & Known Issues
- Currently, no explicit `TODO` or `FIXME` comments are present in the core source files. The codebase appears mature and clean.

## Fragile Areas
- **macOS Permissions (TCC)**: `ScreenCaptureKit` and `AVFoundation` microphone access require user approval. TCC dialogs in macOS can be flaky or confusing for users. Error handling here (e.g., in `RecorderCoordinator`) needs to be robust, as rejection silently fails streams if not handled properly.
- **Audio Mixing & Sample Rates**: `AudioMixerService` and `PCMBufferSampleExtractor` handle real-time audio streams. Mismatched sample rates between the system audio output and microphone input involve complex resampling or synchronizing, which is notoriously difficult to get right without dropping frames.
- **Concurrency & State Machines**: `RecorderCoordinator` relies heavily on careful state transitions (`preparing` -> `recording` -> `finalizing`). If an error is thrown, recovery paths must precisely clean up both `MicCaptureService` and `CaptureService` to avoid zombie audio taps or lingering recording indicators.

## Performance
- **Buffer Storage**: Storing raw audio buffers in memory (`RecordingBufferStore`) before writing them to disk can lead to enormous memory usage during long recordings. `systemSamples` and `micSamples` arrays grow indefinitely until `stopAndFinalize()` is called. A streaming writer to disk would be safer for long sessions.
