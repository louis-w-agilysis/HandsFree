# Roadmap

Phased so each step is independently useful and testable — not a fixed schedule.

- [ ] **Phase 0 — Backend loop, no app yet.** Get the Claude tool-use conversation loop working against `backend/` using a plain HTTP client (curl/Postman) or a tiny CLI script. Prove the streaming + tool-use shape works before any Swift is written.
- [ ] **Phase 1 — iOS shell, conversational only.** SwiftUI app, push-to-talk (no wake word yet), on-device STT, calls the backend, speaks the response via `AVSpeechSynthesizer`. This alone covers the "conversational learning/discussion" v1 goal end to end.
- [ ] **Phase 2 — Reminders & navigation.** Lowest-risk App Intents/SDK integrations (`EventKit`, `MapKit`) — do these before media/messages since the APIs are first-party and well-documented.
- [ ] **Phase 3 — Media playback.** Start with Apple Music (`MusicKit`) since it needs no third-party SDK; add Spotify's SDK as a second integration once the pattern is proven.
- [ ] **Phase 4 — Messages & notifications.** Needs its own research spike first (see the open risk in [architecture.md](architecture.md)) — Apple's restrictions here are the least clear of the four v1 areas.
- [ ] **Phase 5 — Wake word.** Swap push-to-talk for on-device wake-word activation (Porcupine) as the default; keep push-to-talk as a fallback.
- [ ] **Phase 6 — Polish / stretch.** Siri phrase tuning, home screen widget, evaluate whether this is ever worth taking to the App Store (revisit [decisions.md](decisions.md) if so — that's also the only currently-planned path back to needing the paid Apple Developer Program).

## Immediate next steps

1. Get `backend/` running locally (`npm install && npm run dev` — see [backend/README.md](../backend/README.md)) and confirm a tool-use round trip against Claude works.
2. Push this repo to GitHub (public — see [dev-workflow.md](dev-workflow.md)) so `.github/workflows/ios-build.yml` can start giving compile-check feedback on every push, with no Mac and no Apple account needed.
3. Set up SideStore (one-time PC setup, see [dev-workflow.md](dev-workflow.md)) so Phase 1 onward can actually be installed and used on the iPhone 15 Pro for free.
