# Architecture Map

## Pattern & Layers
The architecture is structured around a central Coordinator pattern with modular, focused services. 

### Presentation / UI Layer
- **SwiftUI Views & ViewModels**: Uses `RecordingPopoverView` for UI and `RecordingViewModel` for state management, operating in a menu bar standard setup.
- **Menu Bar Controller**: `StatusItemController` acts as the bridge connecting AppKit `NSStatusItem` and SwiftUI popover logic.

### Coordinator Layer
- `RecorderCoordinator`: Acts as the central orchestrator routing user intent from UI to the core services (starting, stopping recordings, and handling audio states).
- `RecorderState`: Manages and models the state machine of the current recording process.

### Service / Core Layer
- **Audio subsystem** (`Core/Audio`): Handles mixing, metering, and extracting PCM buffers (`AudioMixerService`, `MicCaptureService`, `PCMBufferSampleExtractor`).
- **Capture subsystem** (`Core/Capture`): Interfaces closely with Apple's `ScreenCaptureKit` (`ScreenCaptureKitAdapter`) to route system audio buffers.
- **Permissions** (`Core/Permissions`): Manages Privacy/Security checks (`PermissionManager`).
- **Persistence** (`Core/Persistence`): Uses `JSONStore` for saving metadata or settings.

## Data Flow
1. **User interaction**: User clicks start recording in `RecordingPopoverView` -> `RecordingViewModel` commands `RecorderCoordinator`.
2. **Setup**: `RecorderCoordinator` delegates to `CaptureService` and `MicCaptureService` to begin streams.
3. **Stream handling**: `ScreenCaptureKitAdapter` emits buffers. `AudioMixerService` pulls from both Mic and System buffers to generate a unified audio track.
4. **Completion**: When stopped, streams are closed and the output file is moved or processed by `Core/Output` logic.
