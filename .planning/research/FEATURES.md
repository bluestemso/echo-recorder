# Research: Features

## Milestone Context
**Subsequent milestone** — Adding live metering, per-source gain sliders, and save location picker to an existing audio-first MVP.

## Table Stakes (Users Expect These)
These features are standard in comparable professional and prosumer audio recorder tools:

| Feature | Why Expected | Complexity |
|---------|-------------|------------|
| Live input level meter per source | Real-time visual feedback to prevent clipping | Medium |
| Color-coded level zones (green/yellow/red) | Instant comprehension of signal health | Low |
| Peak hold indicator on meter | Shows recent transient peaks without constant watching | Low-Medium |
| Per-source gain slider | Adjust relative levels of mic vs system audio | Medium |
| Save location picker (at finalize) | Control where recordings end up | Low |
| Default save directory preference | Avoids re-picking every session | Medium |

## Differentiators (Optional, High Value)
| Feature | Value | Deferred? |
|---------|-------|-----------|
| Numerical dBFS readout alongside meter bars | Precision for power users | Yes — future |
| Mute toggle per source | Quick silence in UI during recording | Maybe — Phase 2 designs mention it |
| Clip warning / level-too-low warning | Proactive guidance | Yes — future |

## Anti-Features (Deliberately Excluded)
- Stereo L/R channel split display — our sources are mono-summed; unnecessary complexity
- LUFS metering — overkill for meeting recording context
- Post-processing EQ / noise removal — out of scope for this app's purpose

## How Features Interact
- **Gain slider** should visually affect the **live meter** in real-time (gain staging feedback loop)
- **Save location** at finalize should default to the app's `AppSettings.defaultSaveDirectory` and offer override
- **Default save directory** stored in `AppSettings` (already modeled in data layer)
