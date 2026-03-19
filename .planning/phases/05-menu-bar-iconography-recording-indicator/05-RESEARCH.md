# Phase 5: Menu Bar Iconography & Recording Indicator - Research

**Researched:** 2026-03-18
**Domain:** macOS menu bar status item iconography (AppKit + SF Symbols) and active-recording visibility cues
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### State Icon Set
- Idle icon: `recordingtape`
- Preparing icon: `recordingtape`
- User-selected `recordingtape` for idle/preparing is an intentional override of the `waveform`/`mic.fill` examples in `ICON-01`
- Recording icon: `record.circle.fill` in red
- Finalizing icon: `externaldrive.badge.checkmark`
- Icons animate during preparing, recording, and finalizing
- Recording icon animation is continuous while in `recording`

### Recording Highlight Style
- Recording indicator style: filled red pill behind/around status icon
- Visual emphasis: medium
- No contrasting stroke (fill only)
- Shape: fully pill-shaped

### Indicator Timing
- Red highlight appears only in `recording` state
- No red shown in `idle`, `preparing`, `pendingFinalize`, or `finalizing`
- Highlight transition uses a quick fade (`100-150ms`)
- If start fails during preparing and recording never begins, red highlight is never shown

### Visibility and Accessibility
- No additional fallback cue (no red dot badge, no extra icon cue)
- Red shade adapts to menu bar appearance (light/dark/translucent) for contrast
- Preferred symbol weight: medium
- Status item accessibility text includes current state (for example, `EchoRecorder recording`)

### Claude's Discretion
- Exact animation implementation details and timing curve
- Exact red color values per appearance mode, while preserving medium emphasis and visibility
- Exact mapping behavior for intermediary/internal state transitions not explicitly listed above, while preserving red highlight only in `recording`

### Deferred Ideas (OUT OF SCOPE)
None - discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ICON-01 | Menu bar icon shows SF Symbol `waveform` or `mic.fill` when idle | Context lock intentionally overrides to `recordingtape`; use requirement note + decision trace so implementation remains compliant with approved override. |
| ICON-02 | Menu bar icon shows SF Symbol `record.circle.fill` (red) when recording | Use non-template colored symbol rendering on `NSStatusItem.button` image path; keep red only in `recording`. |
| ICON-03 | Menu bar icon changes based on recorder state (idle -> preparing -> recording -> finalizing -> idle) | Bind directly to `RecorderCoordinator.$state` and map all canonical states (`idle`, `preparing`, `recording`, `pendingFinalize`, `finalizing`). |
| ICON-04 | Icon update occurs within 100ms of state change | Keep state subscription on main run loop and update button image synchronously in sink; add timing assertion test seam. |
| IND-01 | Menu bar status item shows red background/border when recording is active | Use a pill background in button-backed custom view/layer that toggles only when mapped state is `recording`. |
| IND-02 | Red indicator is clearly visible against any desktop wallpaper | Use appearance-aware red tokens (light/dark/translucent variants) and verify with manual QA matrix across wallpapers. |
| IND-03 | Indicator is removed when recording stops | Derive indicator visibility from state machine (`recording` only), so transition to `pendingFinalize`/`finalizing`/`idle` removes red cue immediately. |
</phase_requirements>

## Summary

This phase should be planned as a focused UI-state rendering change in `StatusItemController`, not as recorder logic work. The recorder lifecycle is already the canonical source of truth (`RecorderCoordinator.state`), so planning should center on replacing the existing title-string presentation with deterministic state-to-icon and state-to-indicator rendering.

The highest leverage architecture choice is to map directly from `RecorderState` to a compact visual model (symbol name, symbol color mode, animation mode, indicator visibility, accessibility label). Doing this avoids binary `isRecording` ambiguity and guarantees compliance with both the locked decisions (e.g., red only in `recording`) and timing requirement ICON-04. Existing `@MainActor` + Combine patterns already match what this phase needs.

The main risk is visual reliability in menu bar conditions: template tint behavior can accidentally strip red icons, and contrast can drift across light/dark/translucent menu bars and busy wallpapers. Plan for explicit rendering rules plus testability seams (mapping unit tests + timing tests + manual contrast checklist) to avoid regressions and rework.

**Primary recommendation:** Implement a single `RecorderState -> StatusItemVisualState` mapper in `StatusItemController`, then drive icon image, red pill indicator, and accessibility label from that model on the main run loop.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AppKit (`NSStatusItem`, `NSStatusBarButton`, `NSImage`) | macOS SDK (project target: macOS 14.0) | Menu bar status item host, icon rendering, button accessibility | Native menu bar API surface; required for status item behavior and direct control over symbol/image rendering. |
| SF Symbols assets (system symbol names) | SF Symbols 7 tooling currently available (Apple, WWDC25 era) | Semantic status glyphs (`recordingtape`, `record.circle.fill`, `externaldrive.badge.checkmark`) | Native symbolography aligned with platform idioms and dynamic weights/scales. |
| Combine + `@MainActor` | Apple platform framework (SDK bundled) | State subscription and UI-safe updates from `RecorderCoordinator.$state` | Existing code already uses this flow; minimizes architectural churn. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI (`NSHostingController` in popover only) | SDK bundled | Existing popover content host | Keep unchanged for this phase; iconography/indicator work remains AppKit-side. |
| XCTest | Xcode 15+ toolchain (repo baseline) | Mapping/timing tests for status item visuals | Use for deterministic phase requirements and timing thresholds. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct AppKit button image updates | Full SwiftUI menu bar extra rewrite | Too large for phase scope; would couple icon task to structural UI rewrite. |
| State-driven mapper | Ad-hoc `if` checks on `isRecording` | Faster initially, but fails intermediary states and creates requirement drift. |
| Appearance-aware token mapping | Single fixed red value | Simpler, but weaker contrast reliability for IND-02 across appearances/wallpapers. |

**Installation:**
```bash
# No package installation required for this phase.
# AppKit, Combine, SwiftUI, and XCTest are provided by the Xcode/macOS SDK toolchain.
```

**Version verification:**
- `npm view` verification is not applicable (no npm dependencies in this phase).
- Verified project platform/toolchain anchors from repo:
  - `project.yml`: macOS deployment target `14.0`
  - `README.md`: Xcode `15+`
  - `EchoRecorder.xcodeproj/project.pbxproj`: `SWIFT_VERSION = 5.0`, `MACOSX_DEPLOYMENT_TARGET = 14.0`

## Architecture Patterns

### Recommended Project Structure
```text
EchoRecorder/
├── UI/MenuBar/
│   ├── StatusItemController.swift        # state subscription + rendering entry point
│   ├── StatusItemVisualState.swift       # NEW: pure state mapper model (recommended)
│   └── RecordingViewModel.swift          # existing UI-facing projection
├── Core/Recording/
│   ├── RecorderCoordinator.swift         # source-of-truth state machine
│   └── RecorderState.swift               # canonical recorder states
└── ...

EchoRecorderTests/
├── UI/
│   ├── StatusItemVisualStateTests.swift  # NEW: mapping correctness (all states)
│   └── StatusItemControllerIconTests.swift # NEW: timing + application behavior
└── ...
```

### Pattern 1: State-Driven Visual Mapping
**What:** Create a compact visual model from `RecorderState` (icon name, color mode, red indicator visibility, accessibility label, animation mode).
**When to use:** Always; this is the core phase pattern.
**Example:**
```swift
// Source: Existing project state model + status item usage
// EchoRecorder/Core/Recording/RecorderState.swift
// EchoRecorder/UI/MenuBar/StatusItemController.swift
struct StatusItemVisualState {
    let symbolName: String
    let isColoredSymbol: Bool
    let showRecordingPill: Bool
    let accessibilityLabel: String
}

func mapVisualState(from state: RecorderState, appName: String) -> StatusItemVisualState {
    switch state {
    case .idle:
        return .init(symbolName: "recordingtape", isColoredSymbol: false, showRecordingPill: false, accessibilityLabel: "\(appName) idle")
    case .preparing:
        return .init(symbolName: "recordingtape", isColoredSymbol: false, showRecordingPill: false, accessibilityLabel: "\(appName) preparing")
    case .recording:
        return .init(symbolName: "record.circle.fill", isColoredSymbol: true, showRecordingPill: true, accessibilityLabel: "\(appName) recording")
    case .pendingFinalize:
        return .init(symbolName: "recordingtape", isColoredSymbol: false, showRecordingPill: false, accessibilityLabel: "\(appName) pending finalize")
    case .finalizing:
        return .init(symbolName: "externaldrive.badge.checkmark", isColoredSymbol: false, showRecordingPill: false, accessibilityLabel: "\(appName) finalizing")
    }
}
```

### Pattern 2: Main-RunLoop AppKit Updates from Recorder State
**What:** Subscribe to `RecorderCoordinator.$state`, receive on main run loop, update `NSStatusItem.button` immediately.
**When to use:** For ICON-04 latency target and deterministic UI updates.
**Example:**
```swift
// Source: Existing project Combine pattern in StatusItemController/RecordingViewModel
recorderCoordinator.$state
    .receive(on: RunLoop.main)
    .sink { [weak self] state in
        self?.applyStatusVisualState(mapVisualState(from: state, appName: "EchoRecorder"))
    }
    .store(in: &cancellables)
```

### Pattern 3: Button-Centric Accessibility Label Synchronization
**What:** Set accessibility label on the status bar button each time visual state changes.
**When to use:** Every state transition.
**Example:**
```swift
// Source: NSStatusBarButton inherits NSButton accessibility surface (Microsoft AppKit API docs)
statusItem.button?.setAccessibilityLabel(visualState.accessibilityLabel)
```

### Anti-Patterns to Avoid
- **Binary `isRecording` mapping only:** Loses `preparing`, `pendingFinalize`, and `finalizing` distinctions required by ICON-03 and context decisions.
- **Mixing recorder state mutations into UI layer:** `StatusItemController` must render state, not alter recorder transitions.
- **Template-only icon rendering for recording state:** Can wash out red semantic cue and violate ICON-02.
- **Showing red pill outside `recording`:** Violates locked timing decision and IND-03.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Menu bar hosting behavior | Custom floating/pinned window acting like menu bar item | `NSStatusBar.system.statusItem(...)` + `NSStatusItem.button` | Native API already handles placement, lifecycle, and interaction semantics. |
| Recorder lifecycle duplication | Separate UI-owned state machine | Existing `RecorderCoordinator` + `RecorderState` | Prevents divergence and race bugs in transitional states. |
| Symbol drawing primitives | Manual vector/path drawing for icons | SF Symbol names via `NSImage(systemSymbolName:...)` + symbol configuration | Built-in symbol rendering gives consistency across scales/weights. |
| Accessibility narration engine | Custom VO event plumbing for simple state text | Button accessibility label updates | Native AX integration is already available on status bar button. |

**Key insight:** most complexity in this phase is state correctness and visual reliability, not graphics primitives; platform APIs already provide the primitives.

## Common Pitfalls

### Pitfall 1: State Drift Between `isRecording` and `RecorderState`
**What goes wrong:** Icon/indicator lag or wrong state in `pendingFinalize`/`finalizing`.
**Why it happens:** UI binds to coarse boolean instead of canonical enum.
**How to avoid:** Bind icon/indicator directly to `RecorderCoordinator.$state`; treat `isRecording` as popover action state only.
**Warning signs:** Red indicator remains visible after `stopCapture()` transitions to `.pendingFinalize`.

### Pitfall 2: Recording Red Disappears Due to Template/Tint Behavior
**What goes wrong:** `record.circle.fill` appears monochrome.
**Why it happens:** Template rendering/tint assumptions in menu bar button image pipeline.
**How to avoid:** Use explicit rendering rules for recording state and verify light/dark appearances manually.
**Warning signs:** Recording icon color matches idle icon in screenshots.

### Pitfall 3: Contrast Fails on Bright/Busy Wallpapers
**What goes wrong:** Red indicator is hard to perceive (IND-02 failure).
**Why it happens:** Single static red and/or insufficient alpha for translucent menu bar conditions.
**How to avoid:** Appearance-aware red tokens + manual contrast matrix (light, dark, high-detail wallpapers).
**Warning signs:** QA feedback reports uncertain recording status on bright backgrounds.

### Pitfall 4: Timing Regression Above 100ms
**What goes wrong:** ICON-04 not met under normal transitions.
**Why it happens:** Deferred async work in sink, animation completion gating, or non-main scheduling delays.
**How to avoid:** Compute mapping synchronously; apply icon immediately on main run loop; keep animation non-blocking.
**Warning signs:** Test instrumentation shows >100ms from state publish to icon application.

## Code Examples

Verified patterns from project + platform docs:

### Create and retain a status item
```swift
// Source: Apple Documentation Archive (Status Bar Programming Topics)
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
```

### Bind recorder state to status item updates
```swift
// Source: Existing project Combine pattern
recorderCoordinator.$state
    .receive(on: RunLoop.main)
    .sink { [weak self] state in
        self?.render(for: state)
    }
    .store(in: &cancellables)
```

### Apply symbol configuration and accessibility text
```swift
// Source: Existing project + AppKit API surface
let symbol = NSImage(systemSymbolName: visual.symbolName, accessibilityDescription: visual.accessibilityLabel)
let configured = symbol?.withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
statusItem.button?.image = configured
statusItem.button?.setAccessibilityLabel(visual.accessibilityLabel)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Title text (`"Echo"`, `"Echo *"`) | SF Symbol-based iconography + state-specific visuals | This phase | Better at-a-glance semantics; less text clutter in menu bar. |
| Boolean recording indicator (`isRecording`) | Enum-driven full lifecycle mapping (`RecorderState`) | Existing architecture already supports this | Correct handling of preparing/pending/finalizing transitions. |
| Single visual cue | Icon + red pill during active recording only | This phase | Improves recording awareness while preserving strict semantic red usage. |

**Deprecated/outdated:**
- Text-asterisk recording cue in status title: replace with iconography and pill indicator per phase scope.

## Open Questions

1. **Best non-fragile implementation for the red pill on `NSStatusBarButton`**
   - What we know: `NSStatusBarButton` is an `NSButton`/`NSView`, so layer/subview customization is possible.
   - What's unclear: Which approach is most stable across menu bar highlight/pressed states (custom subview draw vs layer-backed styling).
   - Recommendation: Plan a thin spike task first, then lock one rendering path before full implementation.

2. **Animation style for symbol transitions in AppKit path**
   - What we know: Context locks require animation during preparing/recording/finalizing and continuous animation while recording.
   - What's unclear: Best implementation strategy that does not delay ICON-04 updates.
   - Recommendation: Separate state update timing from animation playback; icon state changes happen immediately, animation decorates afterward.

3. **Automated IND-02 verification depth**
   - What we know: Requirement asks visibility against any wallpaper, which is inherently perceptual.
   - What's unclear: How much can be unit-tested vs manual QA.
   - Recommendation: Unit-test token/state logic, then gate with explicit manual visual matrix.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode 15+ toolchain, macOS target) |
| Config file | none - scheme/project based (`EchoRecorder.xcodeproj`, generated from `project.yml`) |
| Quick run command | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests` |
| Full suite command | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ICON-01 | Idle/preparing map to locked idle symbol (`recordingtape`) override | unit | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests/testIdleAndPreparingUseRecordingTapeSymbol` | ❌ Wave 0 |
| ICON-02 | Recording maps to red `record.circle.fill` | unit | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests/testRecordingUsesRedRecordCircleFill` | ❌ Wave 0 |
| ICON-03 | Full state transition mapping is correct | unit | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests/testAllRecorderStatesMapToExpectedVisualState` | ❌ Wave 0 |
| ICON-04 | Icon is applied within 100ms of published state change | integration | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemControllerIconTests/testIconUpdateLatencyWithin100ms` | ❌ Wave 0 |
| IND-01 | Red pill visible only while actively recording | unit | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests/testRecordingShowsRedPillOnly` | ❌ Wave 0 |
| IND-02 | Indicator remains visible across appearance/wallpaper contexts | manual + smoke | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemControllerIconTests/testRecordingIndicatorUsesAppearanceAwareColorToken` | ❌ Wave 0 |
| IND-03 | Indicator removed when leaving `recording` | unit | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests/testLeavingRecordingRemovesRedPill` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests`
- **Per wave merge:** `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/StatusItemVisualStateTests -only-testing:EchoRecorderTests/StatusItemControllerIconTests`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `EchoRecorderTests/UI/StatusItemVisualStateTests.swift` - covers ICON-01, ICON-02, ICON-03, IND-01, IND-03
- [ ] `EchoRecorderTests/UI/StatusItemControllerIconTests.swift` - covers ICON-04, IND-02 automation seam
- [ ] Manual visual checklist update (existing QA docs) for wallpaper/appearance contrast matrix for IND-02

## Sources

### Primary (HIGH confidence)
- Internal codebase: `EchoRecorder/UI/MenuBar/StatusItemController.swift`, `EchoRecorder/Core/Recording/RecorderCoordinator.swift`, `EchoRecorder/Core/Recording/RecorderState.swift`, `EchoRecorder/UI/MenuBar/RecordingViewModel.swift` - current architecture, state transitions, and integration anchors
- `project.yml`, `README.md`, `EchoRecorder.xcodeproj/project.pbxproj` - platform/toolchain and test command verification

### Secondary (MEDIUM confidence)
- Apple Documentation Archive - Status Bar Programming Topics (status item creation/lifecycle): https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/StatusBar/Tasks/creatingitems.html
- Microsoft AppKit API mirrors (binding metadata for `NSStatusItem.button`, `NSStatusBarButton`, `NSImage` symbol/config/tint surfaces):
  - https://learn.microsoft.com/en-us/dotnet/api/appkit.nsstatusitem.button?view=xamarin-mac-sdk-14
  - https://learn.microsoft.com/en-us/dotnet/api/appkit.nsstatusbarbutton?view=xamarin-mac-sdk-14
  - https://learn.microsoft.com/en-us/dotnet/api/appkit.nsimage?view=xamarin-mac-sdk-14
- Apple SF Symbols landing page (current symbol ecosystem context): https://developer.apple.com/sf-symbols/

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - strong internal verification; some Apple API pages are JS-gated, so part of API confirmation relies on mirrors/archive.
- Architecture: HIGH - directly derived from current codebase architecture and existing patterns.
- Pitfalls: MEDIUM - based on codebase behavior plus platform behavior patterns; limited current Apple no-JS API detail.

**Research date:** 2026-03-18
**Valid until:** 2026-04-17 (30 days)
