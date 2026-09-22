# HandsFree

A voice-first iOS assistant for situations where you can't look at or touch your phone — driving, first and foremost. You talk; it listens, thinks (via Claude), and acts — playing media, reading and sending messages, setting reminders, starting directions — without you ever touching the screen.

This is a personal project (not an App Store product, for now). See [docs/decisions.md](docs/decisions.md) for why, and how that shapes the design.

## Why this, when Claude/ChatGPT already have CarPlay apps?

Claude and ChatGPT's CarPlay integrations (2026) are voice-only Q&A — they explicitly cannot control the phone or the apps on it. That's the gap this project fills: a real conversational loop *plus* the ability to actually act (play the next podcast episode, reply to a text, start navigation) using iOS's App Intents framework as the action layer. HandsFree itself runs as a standalone iPhone app rather than through CarPlay — Louis's car doesn't have it, and the core value (never touching the screen) doesn't depend on it. Full research and competitive landscape: [docs/research.md](docs/research.md).

## How it works

```
Wake word (on-device)
  → Streaming speech-to-text (on-device)
  → Backend proxy → Claude API (streaming, tool use)
  → App Intents execute the chosen action locally
  → Text-to-speech response
```

Full architecture and the open technical questions it depends on: [docs/architecture.md](docs/architecture.md).

## Repo structure

```
HandsFree/
├── docs/           Research, architecture, roadmap, decision log — read these first
├── ios/            The Swift/SwiftUI app: voice pipeline, App Intents action layer
├── backend/        Cloudflare Worker that holds the Claude API key and proxies requests
└── .github/        CI workflows that build the app on a macOS runner — see below
```

## Getting started (no Mac, no cost beyond Claude API usage)

Louis doesn't own a Mac; only device access is an iPhone 15 Pro. The whole dev loop is built around that constraint — see [docs/dev-workflow.md](docs/dev-workflow.md) for the full explanation. Short version: edit here → push to GitHub → a free macOS CI runner builds it → install on the iPhone via [SideStore](https://docs.sidestore.io) (free Apple ID sideloading, no TestFlight, no $99/year Apple fee — not currently needed at all, see [docs/decisions.md](docs/decisions.md)).

- **Backend**: see [backend/README.md](backend/README.md). Node + `npm install` + `wrangler dev` — works on any OS, including this Windows machine.
- **iOS app**: see [ios/README.md](ios/README.md) and [docs/dev-workflow.md](docs/dev-workflow.md). Built via GitHub Actions, not a local Xcode install.

## Status

Early scaffolding stage — see [docs/roadmap.md](docs/roadmap.md) for the phased plan. Nothing has been built end-to-end yet.
