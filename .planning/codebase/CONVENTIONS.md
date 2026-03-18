# Conventions Map

## Code Style & Patterns
- **Concurrency**: Modern Swift concurrency (`async`/`await`) is used extensively for asynchronous tasks (e.g., stopping capture, requesting permissions). Threads are also managed securely via `NSLock` for synchronous buffer writing (e.g., `RecordingBufferStore`).
- **State Management**: Uses `ObservableObject` and `@Published` properties (Combine) to bind core logic (`RecorderCoordinator`, `RecordingViewModel`) to `SwiftUI` views.
- **Dependency Injection**: Services are injected via initializers. Protocols are heavily used with `any ProtocolName` syntax for abstraction (e.g., `capture: any CaptureServicing`).
- **Attributes**: `@MainActor` is heavily favored for coordinating classes (like `RecorderCoordinator` and `AppDelegate`) to ensure UI safety.
- **Class Declarations**: Classes are often marked `final` to optimize dispatch and prevent inheritance.
- **Access Control**: Uses `private` and `private(set)` to encapsulate state tightly.

## Error Handling
- Custom Swift `Error` enums are heavily used (e.g., `RecorderCoordinatorError`).
- Errors are propagated using standard `throws` and `do/catch` blocks.
