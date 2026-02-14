# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CW Carver (bundle ID: `com.blanxlait.cwcarver`) is a native SwiftUI iOS app for learning Morse code using the Koch method. No external dependencies — pure Apple frameworks only.

## Build & Run

Open `MorseTrainer.xcodeproj` in Xcode 15+. The project has two targets:
- **MorseTrainer** — main app (iOS 16.0+, arm64)
- **MorseTrainerWidget** — WidgetKit extension for lock screen widgets

Build from Xcode or CLI:
```bash
xcodebuild -project MorseTrainer.xcodeproj -scheme MorseTrainer -destination 'platform=iOS Simulator,name=iPhone 16' build
```

There are no automated tests currently. Haptic feedback requires a physical device (simulators don't support it).

## Architecture

MVVM with SwiftUI. All services and view models are `@MainActor`.

**Data flow:** `MorseTrainerApp` creates `ProgressManager` as a `@StateObject` and injects it as an `@EnvironmentObject` through the view hierarchy.

### Models
- `MorseCharacter` — character ↔ dit/dah pattern mapping
- `KochSequence` — the 40-character Koch ordering (most distinctive sounds first)
- `UserProgress` — per-character accuracy tracking, unlock state

### Services
- `AudioEngine` — real-time sine wave synthesis via `AVAudioEngine`. Plays dit/dah tones, feedback sounds, and text-to-speech. Configured for background playback (`.playback` category, `.mixWithOthers`).
- `HapticManager` — singleton; maps dit → light impact, dah → medium impact. Pre-prepares generators for low latency.
- `ProgressManager` — persists all state to `UserDefaults`. Manages Koch progression (90% accuracy on 10+ attempts to unlock next character).

### ViewModels
- `DrillViewModel` — core training loop: play random character → accept input → score → advance
- `SettingsViewModel` — wraps `UserDefaults` settings with `@Published` properties

### Views
- `MainMenuView` → `DrillView`, `SettingsView`, `StatsView`
- `DrillView` uses `CharacterButton` components for answer input
- Deep linking via `morsetrainer://` URL scheme (quickstart, character drill)

### Widget Extension
`MorseTrainerWidget/` — `TimelineProvider` rotates through Koch sequence daily. Supports small (character only) and medium (character + quick-start) sizes.

## Key Domain Concepts

- **Koch method**: teach characters ordered by distinctiveness, not alphabetically. Learner masters each character at speed before adding the next.
- **Farnsworth spacing**: characters sent at full speed but with extra spacing between them, easing recognition for beginners.
- **Character WPM** (15–35): speed of individual dit/dah elements. **Farnsworth WPM** (3–20): inter-character spacing.
- **Tone frequency**: configurable 400–1000 Hz (default 700 Hz).
- **Eyes-closed mode**: keyboard-only input with minimal visual feedback for accessibility.
