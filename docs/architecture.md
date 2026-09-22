# Architecture

## Overview

```
 ┌─────────────────────────────── iOS app ───────────────────────────────┐
 │                                                                        │
 │  Wake word          Streaming STT        Conversation        TTS      │
 │  (Porcupine,    →   (WhisperKit /   →    Store (state,   →  (AVSpeech-│
 │   on-device)         SpeechAnalyzer,      history, tool          Synth-│
 │                      on-device)           dispatch)              esizer)│
 │                                                 │                      │
 │                                                 ▼                      │
 │                                          App Intents layer             │
 │                                     (own intents + per-service         │
 │                                      SDKs the tool calls invoke)       │
 └───────────────────────────────────┬────────────────────────────────────┘
                                      │  HTTPS (streamed)
                                      ▼
                        ┌──────────────────────────┐
                        │  Backend (Cloudflare      │
                        │  Worker) — holds the      │
                        │  Anthropic API key,       │
                        │  proxies /converse,       │
                        │  passes through Claude's  │
                        │  streamed tool-use SSE    │
                        └──────────────┬───────────┘
                                       ▼
                              Claude API (Messages,
                              streaming, tool use)
```

## Why a backend at all, for a personal-use app?

The Claude API key must never ship inside the iOS app bundle — anyone could extract it from the binary. The backend's only jobs for now: hold the key as a Cloudflare secret, forward the conversation + tool schema to Claude, and stream the response back. Deliberately thin — see [decisions.md](decisions.md).

## Voice pipeline

- **Wake word**: on-device (Porcupine or similar), see [research.md](research.md). Chosen over always-streaming-to-cloud for latency, battery, and privacy, and to satisfy zero-touch hands-free law requirements in every US state that regulates it.
- **STT**: on-device via `SFSpeechRecognizer` (`requiresOnDeviceRecognition = true`) for now — chosen over WhisperKit/SpeechAnalyzer because it needs no extra SPM dependency and its APIs exist in the SDK this project's CI currently builds against (Xcode 16.4 doesn't yet know about the iOS 26 SpeechAnalyzer APIs). Swappable — the app depends on a small protocol (`SpeechTranscribing`), not a specific SDK, so this can change later without touching the rest of the app.
- **TTS**: `AVSpeechSynthesizer` (on-device, fast, offline) as the default. A higher-quality cloud voice (e.g. ElevenLabs) is a plausible later upgrade for non-latency-critical responses — keep this behind the same kind of protocol seam as STT.

## The Claude conversation loop

Standard tool-use loop against the Messages API, run from the backend:

1. iOS sends the user's transcribed utterance + recent conversation history to `POST /converse`.
2. Backend calls Claude with `tools` = the schema in `backend/src/tools/schema.ts` (one entry per action the app can take — play media, send message, add reminder, get directions, etc.).
3. Response streams back. If Claude emits a `tool_use` block, the backend passes it straight through to the app (rather than executing it itself — the backend has no access to the phone).
4. The iOS app executes the corresponding local action (an App Intent, an SDK call, a deep link — see below), then sends the tool result back through the same conversation for Claude to react to (e.g. confirm out loud, or handle an error by trying something else).
5. Claude's final text response is spoken via TTS.

## The action layer: how "control other apps" actually works

This is the least proven part of the design — flagged as an open risk in [decisions.md](decisions.md). App Intents is the *system's* mechanism for exposing actions to Siri/Shortcuts/Spotlight — it does not appear to give one third-party app a public API to directly call another third-party app's intents. So the realistic v1 plan, per action area:

- **Media playback**: MusicKit / `MPMusicPlayerController` for Apple Music; Spotify's iOS SDK (`SpotifyiOS`) for Spotify; AVPlayer-based for Podcasts if no richer API exists. Each is its own integration, not a generic "media" abstraction until proven otherwise.
- **Reminders & navigation**: `EventKit` (reminders/calendar) and `MapKit`/`MKMapItem.openInMaps` (directions) are first-party frameworks with real public APIs — lowest risk, do these first.
- **Messages & notifications**: most constrained by Apple's platform restrictions (no general "send an SMS programmatically" API for third-party apps outside `MessageUI`'s user-facing compose sheet, which isn't fully hands-free). Needs its own research spike before committing to an approach — possibly `MFMessageComposeViewController` pre-filled + auto-send is *not* allowed, so this may end up needing a Shortcuts-based workaround or an accepted UX compromise (e.g. read notifications aloud via `Notification Center`/`UNUserNotificationCenter` access, reply by handing off to Siri's own message-sending, rather than the app doing it directly).
- **Our own intents** (`AskHandsFreeIntent`, etc.): donated via `AppIntent` + `AppShortcutsProvider` so Siri/Shortcuts/Spotlight can trigger *this* app — this direction is well-supported and low-risk.

## In-car use, without CarPlay

Not used — Louis's car doesn't have CarPlay (see [decisions.md](decisions.md)). HandsFree runs as a standalone iPhone app: mounted in the car, screen unused while driving, audio via `AVAudioSession` (category `.playAndRecord`, so wake-word listening and TTS playback work simultaneously) routing automatically to whatever Bluetooth audio the car already supports, or the phone's speaker otherwise. Ordinary Bluetooth audio output needs no special entitlement, unlike CarPlay — this is standard `AVFoundation` behavior any app gets for free once a Bluetooth audio device is paired.

## Siri

The app donates its own App Intents so `"Hey Siri, ask HandsFree to…"` and a Shortcuts automation (e.g. auto-launch on Bluetooth car-audio connect) both work. This is separate from — and much simpler than — the App Intents-as-tool-layer question above; donating intents *from* this app is standard, documented Apple API.

## Module boundaries (why the iOS source is laid out this way)

- `Voice/` — protocols + implementations for wake word, STT, TTS. Nothing here should know about Claude or tool schemas.
- `Assistant/` — the conversation loop and Claude client. Knows about `Voice/` (to trigger listening/speaking) and about `Intents/` (to dispatch tool calls), but `Voice/` and `Intents/` don't know about each other.
- `Intents/` — the action layer: the app's own donated intents, plus the tool-call handlers that wrap per-service SDKs.

Keeping these boundaries means a voice-pipeline swap (e.g. WhisperKit → SpeechAnalyzer) or a new tool integration touches one module, not the whole app.
