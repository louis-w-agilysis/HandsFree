# Decisions log

Lightweight ADR-style record of choices made and why, so future-you doesn't have to re-derive them. Add a new entry rather than editing old ones when a decision changes — note what superseded what.

## 2026-09-22 — Initial project scoping

**Personal use first, not an App Store product (yet).**
Why: avoids App Store review, privacy policy, subscription billing, and the CarPlay entitlement application up front — all of which are real work but irrelevant until the core loop actually works and gets used day-to-day.
How to apply: don't add auth/billing/legal scaffolding until this decision is revisited. Sideload via SideStore, not TestFlight (see the 2026-09-22 dev-workflow entry below for why). Revisit once the app is something you'd want to hand to someone else.

**Wake-word activation, on-device, as the default.**
Why: zero-touch is the safest activation model across every US hands-free jurisdiction (see [research.md](research.md)), and on-device keeps the mic audio private and low-latency.
How to apply: push-to-talk (CarPlay button / Siri phrase) is still worth having as a fallback/manual trigger, but wake word is the primary path — don't design the voice pipeline assuming a button press is always available.

**v1 scope covers four action areas**: media playback, open conversation/teaching, messages & notifications, navigation & reminders.
Why: this is the full set the project is meant to solve for, not a narrowed-down MVP — the user confirmed all four matter.
How to apply: build in phases (see [roadmap.md](roadmap.md)) rather than all four at once — conversational mode first since it needs no App Intents integration work, then layer in the others roughly in order of how tractable their APIs are (media/reminders/navigation have real SDKs; messaging is more constrained by Apple's platform restrictions and needs its own research pass).

**Backend: serverless (Cloudflare Workers).**
Why: chosen over a self-hosted box for zero maintenance burden and to leave room for this to grow beyond single-user without a re-architecture.
How to apply: `backend/` is a Cloudflare Worker (TypeScript). Keep it a thin proxy — auth/API-key handling and the Claude tool-use loop — not a place business logic accumulates.

**iOS native (Swift/SwiftUI), not cross-platform.**
Why: the entire value proposition is deep OS integration — App Intents, CarPlay, Siri, on-device speech frameworks. Cross-platform frameworks fight these rather than help.
How to apply: don't reconsider this unless the project pivots to needing Android — at which point it's likely a second, mostly-separate native app rather than a shared codebase.

**Open risk, not yet decided**: how "control other apps" (e.g. Spotify) actually gets implemented — App Intents doesn't appear to offer generic app-to-app invocation (see [research.md](research.md)). This needs a research/spike pass before Phase 2 of the roadmap, likely per-integration (Spotify SDK, MusicKit, EventKit, MapKit, Shortcuts deep links).

## 2026-09-22 — No-Mac dev workflow: free sideloading via SideStore, defer the Apple Developer Program fee

**Development and daily use stay fully free (aside from Claude API usage) through Phase 5; the $99/year Apple Developer Program fee is deferred until Phase 6 (CarPlay).**
Why: the CarPlay entitlement request is confirmed gated behind a paid Developer Program account — there's no way around that one. But TestFlight (which does need the paid Program) isn't actually required to install and use the app on your own iPhone day-to-day: SideStore provides free sideloading via a free Apple ID, self-refreshing the 7-day certificate on-device with no computer or cable needed after one-time setup. Since Phases 1–5 don't touch CarPlay, there's no reason to pay before Phase 6.
How to apply: build device-target .ipas via `.github/workflows/ios-sideload-build.yml` (unsigned, GitHub Actions artifact) and install via SideStore rather than TestFlight, until you deliberately decide to start Phase 6. `ios-testflight.yml` stays dormant until then — see [dev-workflow.md](dev-workflow.md).

**Not a legal gray area, unlike the Hackintosh-VM option that was considered and rejected.** SideStore/AltStore automate Apple's own official free developer-signing mechanism (the same thing Xcode does with a free Apple ID) via non-Xcode client software — it doesn't touch Apple's macOS license the way running macOS on non-Apple hardware would. Worth remembering if this decision is ever revisited, so it isn't conflated with that rejected option.
