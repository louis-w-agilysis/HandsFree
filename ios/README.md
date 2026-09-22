# ios

The HandsFree iOS app: voice pipeline, App Intents action layer. Runs as a standalone app on the phone (no CarPlay — see [../docs/decisions.md](../docs/decisions.md)). See [../docs/architecture.md](../docs/architecture.md) for how the pieces fit together.

Building this normally requires a Mac with Xcode — this project doesn't have one, so building happens on GitHub Actions' macOS runners instead, and installing on the phone happens via SideStore rather than a direct Xcode-to-device connection. Full explanation: [../docs/dev-workflow.md](../docs/dev-workflow.md). Nothing here has been built or run yet — that's the first task, via CI, not locally.

## Setup

The Xcode project itself (`HandsFree.xcodeproj`) is generated from [`project.yml`](project.yml) rather than committed — this keeps the repo diff-friendly (no opaque `.pbxproj` merge conflicts) and keeps project configuration in one readable file. CI (`.github/workflows/`) runs `xcodegen generate` automatically on every build. The commands below are only needed if you're ever on a Mac (own, rented, or borrowed) and want to work interactively:

```
brew install xcodegen
cd ios
xcodegen generate
open HandsFree.xcodeproj
```

## Adding dependencies

As phases in the roadmap need them, add via Xcode's Swift Package Manager integration (File → Add Package Dependencies):

- **WhisperKit** (`argmaxinc/WhisperKit`) or Apple's built-in `SpeechAnalyzer` — an upgrade from the current `SFSpeechRecognizer`-based transcriber (see `Voice/SpeechTranscriber.swift`) if/when better accuracy or lower latency is worth the added dependency or a CI toolchain bump.
- **Porcupine** (`Picovoice/porcupine`) — on-device wake-word detection, Phase 5.
- **Spotify iOS SDK** — Phase 3, if adding Spotify control alongside Apple Music.

## Source layout

```
Sources/HandsFree/
├── App/            App entry point
├── UI/             SwiftUI views (phone screen)
├── Voice/          Wake word, speech-to-text, text-to-speech — no knowledge of Claude
├── Assistant/       Conversation state + the backend client
└── Intents/        Donated App Intents (Siri hooks) + tool-call handlers (the action layer)
```
