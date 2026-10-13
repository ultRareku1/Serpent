# Serpent

[🇺🇸 English](README.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md) · [🇯🇵 日本語](README.ja.md) · [🇰🇷 한국어](README.ko.md) · [🇫🇷 Français](README.fr.md) · [🇩🇪 Deutsch](README.de.md) · [🇪🇸 Español](README.es.md)

A native, minimalist Snake game for Apple Silicon Macs, built with SwiftUI, AppKit, and AVFoundation. No third-party runtime dependencies or network requests.

## Getting Started

Open `dist/Serpent.app`, or extract `dist/Serpent-Apple-Silicon.zip`. You can drag the app into your Applications folder. Requires an M-series Mac running macOS 13 Ventura or later.

The local build is ad-hoc signed and has not been notarized with an Apple Developer ID. If macOS blocks the app after you download it on another Mac, follow the system's guidance to allow it to open.

## Controls

| Action | Control |
| --- | --- |
| Move | Arrow keys, WASD, or drag/swipe on the game board |
| Start, pause, or resume | Space |
| New game | R or ⌘N |
| Pause or close settings/help | Esc |
| Settings | ⌘, |

Collect food to grow your snake. Hitting a wall ends the round unless **Wrap edges** is enabled; hitting your own body always ends it. Direct 180° turns are ignored, and rapid valid turns are queued and applied on successive movement steps.

The game pauses automatically when you switch to another app, minimize the window, or put your Mac to sleep. Press Space to resume when you return.

## Features

- Native desktop window with resizing, full-screen support, and Retina/high-DPI rendering.
- Light, dark, and system appearance options. Follows your Mac's appearance by default.
- Smooth rendering at 60 Hz, gently pulsing food, and animated score updates.
- Three difficulty levels, each with its own best-score record:

  | Difficulty | Time per move | Points per food |
  | --- | --- | --- |
  | Easy | 160 ms | 10 |
  | Normal | 105 ms | 20 |
  | Hard | 70 ms | 30 |

  Difficulty changes take effect in the next game.

- Independent **Wrap edges** toggle in **Settings → Gameplay**, off by default. When enabled, crossing an edge brings the snake out of the opposite edge. Changes apply to the next game; hitting your own body still ends the round. Best scores are recorded separately for each difficulty and mode, preserving existing classic scores.

- Optional, softly synthesized sound cues for starting, collecting food, pausing, ending a round, and setting a new record.
- Best scores, preferences, and language selections are saved locally.
- Eight fully localized languages, selectable with flags in Settings:

  | Language | Region |
  | --- | --- |
  | 🇺🇸 English | United States |
  | 🇨🇳 Simplified Chinese | China |
  | 🇹🇼 Traditional Chinese | Taiwan |
  | 🇯🇵 Japanese | Japan |
  | 🇰🇷 Korean | South Korea |
  | 🇫🇷 French | France |
  | 🇩🇪 German | Germany |
  | 🇪🇸 Spanish | Spain |

  The default language follows your Mac's preferred languages. You can change it at any time in Settings.

## Development and Packaging

Requires Xcode Command Line Tools and Swift 5.9 or later.

```sh
swift test
swift run Serpent
./Scripts/build-app.sh
```

The packaging script creates an arm64 app and ZIP archive, then verifies the app's signature. Run `BUILD_DMG=1 ./Scripts/build-app.sh` to also generate a disk image.

Automated tests cover game rules, the turn queue, edge cases, automatic pausing, system language matching, and localization completeness across all eight languages.

Source files are in `Sources/Serpent`, translations in `Sources/Serpent/Resources`, and the app icon and metadata in `Support`.
