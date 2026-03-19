---
phase: 06
slug: popover-ux-improvements
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-19
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode 15+ / macOS unit tests) |
| **Config file** | none - Xcode project/scheme driven via `project.yml` |
| **Quick run command** | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/UI/RecordingViewModelTests` |
| **Full suite command** | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS'` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/UI/RecordingViewModelTests`
- **After every plan wave:** Run `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/UI/RecordingRuntimeFlowTests -only-testing:EchoRecorderTests/UI/StatusItemControllerIconTests`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | POPOV-01, POPOV-02 | unit | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/UI/FinalizeViewStateTests` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | POPOV-03, POPOV-04, POPOV-05, ANIM-03 | unit/integration | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/UI/FinalizeTransitionTimingTests -only-testing:EchoRecorderTests/UI/RecordingRuntimeFlowTests` | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 2 | ANIM-01, ANIM-02 | unit + manual | `xcodebuild test -project EchoRecorder.xcodeproj -scheme EchoRecorder -destination 'platform=macOS' -only-testing:EchoRecorderTests/UI/PopoverAnimationPolicyTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending - ✅ green - ❌ red - ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `EchoRecorderTests/UI/FinalizeViewStateTests.swift` - stubs for POPOV-01/02/03 state rendering contracts
- [ ] `EchoRecorderTests/UI/PopoverAnimationPolicyTests.swift` - stubs for ANIM-01/02 popover animation policy
- [ ] `EchoRecorderTests/UI/FinalizeTransitionTimingTests.swift` - stubs for POPOV-05/ANIM-03 timing constants and reduce-motion fallback policy

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Popover appears/disappears with no perceptible fade on target macOS runtime | ANIM-01, ANIM-02 | `NSPopover.animates` is documented as a hint, so runtime visual behavior can vary | Launch app, toggle popover 10 times in idle and recording states, confirm no visible fade-in/out; if any fade appears, capture screen recording and mark failure |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
