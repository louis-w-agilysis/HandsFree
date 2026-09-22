# Roadmap

Phased so each step is independently useful and testable — not a fixed schedule.

- [x] **Phase 0 — Backend loop, no app yet.** Verified 2026-09-22 via curl against the local `wrangler dev` server: plain text streaming works, and the tool-use shape (`add_reminder`) round-trips correctly — the `partial_json` fragments Claude streams reconstruct into valid JSON exactly as `ClaudeClient.swift` expects.
- [ ] **Phase 1 — iOS shell, conversational only.** SwiftUI app, push-to-talk (no wake word yet), on-device STT, calls the backend, speaks the response via `AVSpeechSynthesizer`. Code is written and passes CI (compiles + Apple's App Intents metadata validation), but not yet confirmed running on-device — needs SideStore installed (see [dev-workflow.md](dev-workflow.md)) before this can be checked off.
- [ ] **Phase 2 — Reminders & navigation.** Lowest-risk App Intents/SDK integrations (`EventKit`, `MapKit`) — do these before media/messages since the APIs are first-party and well-documented.
- [ ] **Phase 3 — Media playback.** Start with Apple Music (`MusicKit`) since it needs no third-party SDK; add Spotify's SDK as a second integration once the pattern is proven.
- [ ] **Phase 4 — Messages & notifications.** Needs its own research spike first (see the open risk in [architecture.md](architecture.md)) — Apple's restrictions here are the least clear of the four v1 areas.
- [ ] **Phase 5 — Wake word.** Swap push-to-talk for on-device wake-word activation (Porcupine) as the default; keep push-to-talk as a fallback.
- [ ] **Phase 6 — Polish / stretch.** Siri phrase tuning, home screen widget, evaluate whether this is ever worth taking to the App Store (revisit [decisions.md](decisions.md) if so — that's also the only currently-planned path back to needing the paid Apple Developer Program).

## Immediate next steps

1. ~~Get `backend/` running locally and confirm a tool-use round trip against Claude works.~~ Done.
2. ~~Push this repo to GitHub (public) so `ios-build.yml` gives compile-check feedback on every push.~~ Done — CI is green.
3. ~~Deploy `backend/` to Cloudflare for real.~~ Done — live at `https://handsfree-backend.louis-woolsey2.workers.dev`, smoke-tested 2026-09-22 (Haiku 4.5, thinking disabled, 7 output tokens for a trivial request). `ClaudeClient.swift` now points at it by default.
4. Set up SideStore (one-time PC setup, see [dev-workflow.md](dev-workflow.md)) and install the app via `ios-sideload-build.yml` so Phase 1 can actually be confirmed working on the iPhone 15 Pro — this is the one remaining step before Phase 1 can be checked off above.
