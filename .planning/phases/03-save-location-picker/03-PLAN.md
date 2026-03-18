---
wave: 1
depends_on: []
files_modified:
  - EchoRecorder/Core/Persistence/SaveLocationService.swift
  - EchoRecorder/Core/Recording/RecorderCoordinator.swift
  - EchoRecorderTests/Core/SaveLocationServiceTests.swift
autonomous: true
---

# Phase 3, Plan 01: Persistence + Coordinator Split (Wave 1)

## Goal

Create `SaveLocationService` for persisting the default save directory, and add `stopCapture()` + `finalizeRecording()` methods to `RecorderCoordinator` to enable the two-step stop flow.

---

## Requirements

- SAVE-01 (partial): Save location infrastructure
- SAVE-02: Default directory fallback
- SAVE-03: Persistence across restarts

---

## Tasks

### Task 1: Create SaveLocationService

<read_first>
- EchoRecorder/Core/Persistence/JSONStore.swift
- EchoRecorder/Core/Output/RecordingFinalizer.swift
</read_first>

<action>
Create `EchoRecorder/Core/Persistence/SaveLocationService.swift`:

```swift
import Foundation

struct SaveLocationService {
    private let store: JSONStore
    private static let key = "defaultSaveDirectory"

    static let defaultFallback: URL =
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        ?? FileManager.default.temporaryDirectory

    init(store: JSONStore) {
        self.store = store
    }

    func load() -> URL {
        guard let path = try? store.load(String.self, from: Self.key),
              !path.isEmpty
        else {
            return Self.defaultFallback
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    func save(_ url: URL) throws {
        try store.save(url.path, as: Self.key)
    }
}
```
</action>

<acceptance_criteria>
- `EchoRecorder/Core/Persistence/SaveLocationService.swift` exists
- File contains `struct SaveLocationService`
- File contains `static let key = "defaultSaveDirectory"`
- File contains `func load() -> URL`
- File contains `func save(_ url: URL) throws`
- File contains `Self.defaultFallback`
</acceptance_criteria>

---

### Task 2: Add stopCapture() + finalizeRecording() to RecorderCoordinator

<read_first>
- EchoRecorder/Core/Recording/RecorderCoordinator.swift
- EchoRecorder/Core/Recording/RecorderState.swift
</read_first>

<action>
In `RecorderCoordinator.swift`:

1. Add a new state `.pendingFinalize` to `RecorderState.swift`:
```swift
enum RecorderState: Equatable {
    case idle
    case preparing
    case recording
    case finalizing
    case pendingFinalize
}
```

2. Add transition rules in `canTransition`:
```swift
case (.recording, .pendingFinalize):
    return true
case (.pendingFinalize, .finalizing):
    return true
case (.pendingFinalize, .idle):
    return true
```

3. Add `stopCapture()` to `RecorderCoordinator` (stops audio, keeps buffer, transitions to `.pendingFinalize`):
```swift
func stopCapture() async throws {
    transition(to: .pendingFinalize)
    if mic.isCapturing {
        try mic.stopCapture()
    }
    if capture.isRunning {
        try await capture.stopCapture()
    }
    capture.onSystemAudioSamples = nil
    mic.onMicSamples = nil
    latestSystemMeterLevel = .zero
    latestMicMeterLevel = .zero
    onMeterSnapshot?(.zero, .zero)
}
```

4. Add `finalizeRecording(recordingName:overrideDirectory:)` (uses buffered data, transitions to idle):
```swift
func finalizeRecording(recordingName: String, overrideDirectory: URL) async throws -> FinalizedAudioOutput {
    transition(to: .finalizing)
    do {
        let recordingData = recordingBufferStore.snapshot()
        let output = try finalizer.finalize(
            fileName: recordingName,
            overrideDirectory: overrideDirectory,
            recordingData: recordingData
        )
        transition(to: .idle)
        return output
    } catch {
        transition(to: .idle)
        throw error
    }
}
```

Also update `bindRecorderState` call-sites in `RecordingViewModel` — the existing `stopAndFinalize` still works for tests; keep it. New API is additive only.
</action>

<acceptance_criteria>
- `RecorderState.swift` contains `case pendingFinalize`
- `RecorderCoordinator.swift` contains `func stopCapture() async throws`
- `RecorderCoordinator.swift` contains `func finalizeRecording(recordingName: String, overrideDirectory: URL) async throws`
- `canTransition` handles `.recording → .pendingFinalize` and `.pendingFinalize → .finalizing`
</acceptance_criteria>

---

### Task 3: Add SaveLocationService Tests

<read_first>
- EchoRecorderTests/Output/RecordingFinalizerTests.swift
- EchoRecorder/Core/Persistence/JSONStore.swift
- EchoRecorder/Core/Persistence/SaveLocationService.swift
</read_first>

<action>
Create `EchoRecorderTests/Core/SaveLocationServiceTests.swift`:

```swift
import XCTest
import Foundation
@testable import EchoRecorder

final class SaveLocationServiceTests: XCTestCase {
    private var tempDirectory: URL!
    private var store: JSONStore!
    private var service: SaveLocationService!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveLocationServiceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        store = JSONStore(baseDirectory: tempDirectory)
        service = SaveLocationService(store: store)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testLoadReturnsFallbackWhenNothingPersisted() {
        let loaded = service.load()
        XCTAssertEqual(loaded, SaveLocationService.defaultFallback)
    }

    func testSaveAndLoadRoundTrip() throws {
        let target = URL(fileURLWithPath: "/tmp/echo-test-recordings", isDirectory: true)
        try service.save(target)
        let loaded = service.load()
        XCTAssertEqual(loaded.path, target.path)
    }
}
```
</action>

<acceptance_criteria>
- `EchoRecorderTests/Core/SaveLocationServiceTests.swift` exists
- Contains `testLoadReturnsFallbackWhenNothingPersisted`
- Contains `testSaveAndLoadRoundTrip`
</acceptance_criteria>

---

## Verification

```bash
xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' \
  -only-testing:EchoRecorderTests/SaveLocationServiceTests
```
Expected: 2 tests pass.

---

## Must-Haves
- [ ] `SaveLocationService.load()` returns Downloads when no key persisted
- [ ] `SaveLocationService.save()` + `load()` round-trip works
- [ ] `RecorderCoordinator.stopCapture()` exists and stops audio without writing files
- [ ] `RecorderCoordinator.finalizeRecording()` writes files and transitions to idle

---

wave: 2
depends_on: [01]
files_modified:
  - EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift
  - EchoRecorderTests/Output/FinalizeRecordingViewModelTests.swift
autonomous: true
---

# Phase 3, Plan 02: FinalizeRecordingViewModel Expansion (Wave 2)

## Goal

Expand `FinalizeRecordingViewModel` to own directory picker state and trigger `NSOpenPanel` for directory picking.

---

## Requirements

- SAVE-01: Show current target directory with "Change Location" button
- SAVE-02: Default directory fallback when no directory chosen

---

## Tasks

### Task 4: Expand FinalizeRecordingViewModel

<read_first>
- EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift
- EchoRecorder/Core/Persistence/SaveLocationService.swift
- EchoRecorder/Core/Output/RecordingFinalizer.swift
- EchoRecorderTests/Output/FinalizeRecordingViewModelTests.swift
</read_first>

<action>
Replace `FinalizeRecordingViewModel.swift` with the expanded version:

```swift
import AppKit
import Combine
import Foundation

@MainActor
final class FinalizeRecordingViewModel: ObservableObject {
    @Published private(set) var finalizedOutput: FinalizedAudioOutput?
    @Published var selectedDirectory: URL

    var finalizedURL: URL? {
        finalizedOutput?.mixed
    }

    var displayPath: String {
        selectedDirectory.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    private let finalizer: RecordingFinalizer
    private let saveLocationService: SaveLocationService

    init(finalizer: RecordingFinalizer, saveLocationService: SaveLocationService) {
        self.finalizer = finalizer
        self.saveLocationService = saveLocationService
        self.selectedDirectory = saveLocationService.load()
    }

    func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose where to save the recording"
        panel.directoryURL = selectedDirectory

        guard panel.runModal() == .OK, let url = panel.url else { return }
        selectedDirectory = url
        try? saveLocationService.save(url)
    }

    func finalizeRecording(fileName: String) throws {
        finalizedOutput = try finalizer.finalize(
            fileName: fileName,
            overrideDirectory: selectedDirectory
        )
    }
}
```
</action>

<acceptance_criteria>
- `FinalizeRecordingViewModel.swift` contains `@Published var selectedDirectory: URL`
- `FinalizeRecordingViewModel.swift` contains `func chooseDirectory()`
- `FinalizeRecordingViewModel.swift` contains `NSOpenPanel()`
- `FinalizeRecordingViewModel.swift` contains `var displayPath: String`
- `FinalizeRecordingViewModel.swift` contains `func finalizeRecording(fileName: String) throws`
- `FinalizeRecordingViewModel.swift` does NOT contain `overrideDirectory` as a parameter on `finalizeRecording`
</acceptance_criteria>

---

### Task 5: Update FinalizeRecordingViewModelTests

<read_first>
- EchoRecorderTests/Output/FinalizeRecordingViewModelTests.swift
- EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift
- EchoRecorder/Core/Persistence/SaveLocationService.swift
- EchoRecorder/Core/Persistence/JSONStore.swift
</read_first>

<action>
Replace `FinalizeRecordingViewModelTests.swift` with updated + expanded tests:

```swift
import Foundation
import XCTest
@testable import EchoRecorder

@MainActor
final class FinalizeRecordingViewModelTests: XCTestCase {
    private var tempDirectory: URL!
    private var store: JSONStore!
    private var saveLocationService: SaveLocationService!
    private var finalizer: RecordingFinalizer!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinalizeVMTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        store = JSONStore(baseDirectory: tempDirectory)
        saveLocationService = SaveLocationService(store: store)
        finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: tempDirectory
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    private func makeViewModel() -> FinalizeRecordingViewModel {
        FinalizeRecordingViewModel(finalizer: finalizer, saveLocationService: saveLocationService)
    }

    func testSelectedDirectoryInitializesFromSaveLocationService() {
        let viewModel = makeViewModel()
        // Fresh store → falls back to default
        XCTAssertEqual(viewModel.selectedDirectory, SaveLocationService.defaultFallback)
    }

    func testSelectedDirectoryInitializesFromPersistedValue() throws {
        let custom = URL(fileURLWithPath: "/tmp/custom-echo", isDirectory: true)
        try saveLocationService.save(custom)
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.selectedDirectory.path, custom.path)
    }

    func testFinalizeRecordingSetsFinalizedURLUnderSelectedDirectory() throws {
        let viewModel = makeViewModel()
        viewModel.selectedDirectory = tempDirectory
        try viewModel.finalizeRecording(fileName: "recording")
        XCTAssertEqual(viewModel.finalizedURL?.lastPathComponent, "mixed.m4a")
        XCTAssertTrue(viewModel.finalizedURL?.path.hasPrefix(tempDirectory.path) == true)
    }

    func testFinalizeRecordingLeavesFinalizedURLUnsetOnError() {
        let viewModel = makeViewModel()
        viewModel.selectedDirectory = tempDirectory
        XCTAssertThrowsError(try viewModel.finalizeRecording(fileName: "../bad-name"))
        XCTAssertNil(viewModel.finalizedURL)
    }

    func testDisplayPathHomeDirIsAbbreviated() {
        let viewModel = makeViewModel()
        viewModel.selectedDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")
        XCTAssertTrue(viewModel.displayPath.hasPrefix("~"))
    }
}
```
</action>

<acceptance_criteria>
- `FinalizeRecordingViewModelTests.swift` contains `testSelectedDirectoryInitializesFromSaveLocationService`
- `FinalizeRecordingViewModelTests.swift` contains `testSelectedDirectoryInitializesFromPersistedValue`
- `FinalizeRecordingViewModelTests.swift` contains `testFinalizeRecordingSetsFinalizedURLUnderSelectedDirectory`
- `FinalizeRecordingViewModelTests.swift` contains `testDisplayPathHomeDirIsAbbreviated`
</acceptance_criteria>

---

## Verification

```bash
xcodebuild test -scheme EchoRecorder -destination 'platform=macOS' \
  -only-testing:EchoRecorderTests/FinalizeRecordingViewModelTests
```
Expected: all 4 tests pass.

---

wave: 3
depends_on: [01, 02]
files_modified:
  - EchoRecorder/UI/Finalize/FinalizeView.swift
  - EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
  - EchoRecorder/UI/MenuBar/RecordingViewModel.swift
  - EchoRecorderTests/UI/RecordingViewModelTests.swift
autonomous: true
---

# Phase 3, Plan 03: FinalizeView UI + RecordingViewModel Wiring (Wave 3)

## Goal

Create `FinalizeView` and wire the two-step stop flow into `RecordingViewModel` and `RecordingPopoverView`.

---

## Requirements

- SAVE-01: Finalize step shows target directory with "Change Location" button
- SAVE-02: Default directory used when none chosen

---

## Tasks

### Task 6: Create FinalizeView

<read_first>
- EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift
- EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
- EchoRecorder/UI/MenuBar/LevelMeterView.swift
</read_first>

<action>
Create `EchoRecorder/UI/Finalize/FinalizeView.swift`:

```swift
import SwiftUI

struct FinalizeView: View {
    @ObservedObject var viewModel: FinalizeRecordingViewModel
    let recordingName: String
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Text("Save Recording")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text(viewModel.displayPath)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Change Location") {
                    viewModel.chooseDirectory()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }

            Button("Save") {
                try? viewModel.finalizeRecording(fileName: recordingName)
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}
```
</action>

<acceptance_criteria>
- `EchoRecorder/UI/Finalize/FinalizeView.swift` exists
- Contains `struct FinalizeView: View`
- Contains `viewModel.displayPath`
- Contains `viewModel.chooseDirectory()`
- Contains `viewModel.finalizeRecording(fileName: recordingName)`
- Contains `Button("Change Location")`
- Contains `Button("Save")`
</acceptance_criteria>

---

### Task 7: Wire RecordingViewModel for Two-Step Stop

<read_first>
- EchoRecorder/UI/MenuBar/RecordingViewModel.swift
- EchoRecorder/Core/Recording/RecorderCoordinator.swift
- EchoRecorder/UI/Finalize/FinalizeRecordingViewModel.swift
- EchoRecorder/Core/Persistence/SaveLocationService.swift
- EchoRecorder/Core/Persistence/JSONStore.swift
</read_first>

<action>
In `RecordingViewModel.swift`:

1. Add imports and new published state:
```swift
import AppKit
```

2. Add after `gainValues`:
```swift
@Published private(set) var pendingFinalize: FinalizeRecordingViewModel?
```

3. Add a `makeFinalizationVM()` helper that builds `SaveLocationService` from the app support directory:
```swift
private static func makeSaveLocationService() -> SaveLocationService {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? FileManager.default.temporaryDirectory
    let store = JSONStore(baseDirectory: appSupport.appendingPathComponent("EchoRecorder", isDirectory: true))
    return SaveLocationService(store: store)
}
```

4. Change `stopRecording(using:)` to call `stopCapture()` then set `pendingFinalize`:
```swift
private func stopRecording(using coordinator: RecorderCoordinator) async {
    do {
        try await coordinator.stopCapture()
        let recordingName = activeRecordingName ?? recordingNameProvider()
        let finalizer = RecordingFinalizer(
            fileWriter: FileWriterService(),
            defaultDirectory: SaveLocationService.defaultFallback
        )
        pendingFinalize = FinalizeRecordingViewModel(
            finalizer: finalizer,
            saveLocationService: RecordingViewModel.makeSaveLocationService()
        )
        // Store name so FinalizeView can use it
        activeRecordingName = recordingName
    } catch {
        latestErrorDescription = error.localizedDescription
        activeRecordingName = nil
    }
}
```

5. Add `func confirmFinalize()` called after user presses Save in FinalizeView:
```swift
func confirmFinalize() {
    guard let finalizingVM = pendingFinalize,
          let recordingName = activeRecordingName,
          let coordinator = recorderCoordinator
    else { return }

    Task { [weak self] in
        do {
            let output = try await coordinator.finalizeRecording(
                recordingName: recordingName,
                overrideDirectory: finalizingVM.selectedDirectory
            )
            self?.lastFinalizedOutput = output
            self?.pendingFinalize = nil
            self?.activeRecordingName = nil
        } catch {
            self?.latestErrorDescription = error.localizedDescription
            self?.pendingFinalize = nil
            self?.activeRecordingName = nil
        }
    }
}
```

NOTE: The `FinalizeRecordingViewModel.finalizeRecording()` is used for standalone finalize (e.g. tests). In the real stop flow, `confirmFinalize()` calls `coordinator.finalizeRecording()` directly so the buffered audio data flows correctly. `FinalizeView.onSave` closure calls `viewModel.confirmFinalize()`.
</action>

<acceptance_criteria>
- `RecordingViewModel.swift` contains `@Published private(set) var pendingFinalize: FinalizeRecordingViewModel?`
- `RecordingViewModel.swift` contains `func confirmFinalize()`
- `RecordingViewModel.swift` contains `try await coordinator.stopCapture()`
- `RecordingViewModel.swift` contains `static func makeSaveLocationService()`
</acceptance_criteria>

---

### Task 8: Update RecordingPopoverView to show FinalizeView

<read_first>
- EchoRecorder/UI/MenuBar/RecordingPopoverView.swift
- EchoRecorder/UI/Finalize/FinalizeView.swift
- EchoRecorder/UI/MenuBar/RecordingViewModel.swift
</read_first>

<action>
In `RecordingPopoverView.swift`, add after the button:

```swift
if let finalizeVM = viewModel.pendingFinalize,
   let recordingName = viewModel.activeRecordingName {
    FinalizeView(
        viewModel: finalizeVM,
        recordingName: recordingName,
        onSave: { viewModel.confirmFinalize() }
    )
}
```

Also expose `activeRecordingName` as `private(set)` on `RecordingViewModel` (currently `private`):
```swift
private(set) var activeRecordingName: String?
```
</action>

<acceptance_criteria>
- `RecordingPopoverView.swift` contains `FinalizeView(`
- `RecordingPopoverView.swift` contains `viewModel.pendingFinalize`
- `RecordingPopoverView.swift` contains `viewModel.confirmFinalize()`
- `RecordingViewModel.swift` has `private(set) var activeRecordingName`
</acceptance_criteria>

---

### Task 9: Add RecordingViewModel Tests for pendingFinalize

<read_first>
- EchoRecorderTests/UI/RecordingViewModelTests.swift
- EchoRecorder/UI/MenuBar/RecordingViewModel.swift
</read_first>

<action>
Append to `RecordingViewModelTests.swift`:

```swift
func testPendingFinalizeIsNilInitially() {
    let viewModel = RecordingViewModel()
    XCTAssertNil(viewModel.pendingFinalize)
}
```
</action>

<acceptance_criteria>
- `RecordingViewModelTests.swift` contains `testPendingFinalizeIsNilInitially`
- `XCTAssertNil(viewModel.pendingFinalize)` present
</acceptance_criteria>

---

## Verification

```bash
xcodebuild test -scheme EchoRecorder -destination 'platform=macOS'
```
Expected: all tests pass (was 76, now higher), 0 failures.
Also run `xcodegen generate` if new files were added.

---

## Must-Haves (Goal-Backward)
- [ ] After stop, popover shows save directory + "Change Location" button + "Save" button
- [ ] "Change Location" opens NSOpenPanel
- [ ] "Save" writes files and dismisses finalize section
- [ ] Chosen directory is persisted and used on next recording
- [ ] Default is Downloads when nothing persisted
