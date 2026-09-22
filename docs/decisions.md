# Decisions log

Lightweight ADR-style record of choices made and why, so future-you doesn't have to re-derive them. Add a new entry rather than editing old ones when a decision changes — note what superseded what.

## 2026-09-22 — Initial project scoping

**Personal use first, not an App Store product (yet).**
Why: avoids App Store review, privacy policy, and subscription billing up front — all of which are real work but irrelevant until the core loop actually works and gets used day-to-day.
How to apply: don't add auth/billing/legal scaffolding until this decision is revisited. Sideload via SideStore, not TestFlight (see the 2026-09-22 dev-workflow entry below for why). Revisit once the app is something you'd want to hand to someone else.

**Wake-word activation, on-device, as the default.**
Why: zero-touch is the safest activation model across every US hands-free jurisdiction (see [research.md](research.md)), and on-device keeps the mic audio private and low-latency.
How to apply: push-to-talk (an in-app button, or a Siri phrase) is still worth having as a fallback/manual trigger, but wake word is the primary path — don't design the voice pipeline assuming a button press is always available.

**v1 scope covers four action areas**: media playback, open conversation/teaching, messages & notifications, navigation & reminders.
Why: this is the full set the project is meant to solve for, not a narrowed-down MVP — the user confirmed all four matter.
How to apply: build in phases (see [roadmap.md](roadmap.md)) rather than all four at once — conversational mode first since it needs no App Intents integration work, then layer in the others roughly in order of how tractable their APIs are (media/reminders/navigation have real SDKs; messaging is more constrained by Apple's platform restrictions and needs its own research pass).

**Backend: serverless (Cloudflare Workers).**
Why: chosen over a self-hosted box for zero maintenance burden and to leave room for this to grow beyond single-user without a re-architecture.
How to apply: `backend/` is a Cloudflare Worker (TypeScript). Keep it a thin proxy — auth/API-key handling and the Claude tool-use loop — not a place business logic accumulates.

**iOS native (Swift/SwiftUI), not cross-platform.**
Why: the entire value proposition is deep OS integration — App Intents, Siri, on-device speech frameworks. Cross-platform frameworks fight these rather than help.
How to apply: don't reconsider this unless the project pivots to needing Android — at which point it's likely a second, mostly-separate native app rather than a shared codebase.

**Open risk, not yet decided**: how "control other apps" (e.g. Spotify) actually gets implemented — App Intents doesn't appear to offer generic app-to-app invocation (see [research.md](research.md)). This needs a research/spike pass before Phase 2 of the roadmap, likely per-integration (Spotify SDK, MusicKit, EventKit, MapKit, Shortcuts deep links).

## 2026-09-22 — No-Mac dev workflow: free sideloading via SideStore

**Development and daily use stay fully free (aside from Claude API usage) — TestFlight/the paid Apple Developer Program are not part of the plan.**
Why: TestFlight (which needs the paid Program) isn't actually required to install and use the app on your own iPhone day-to-day: SideStore provides free sideloading via a free Apple ID, self-refreshing the 7-day certificate on-device with no computer or cable needed after one-time setup.
How to apply: build device-target .ipas via `.github/workflows/ios-sideload-build.yml` (unsigned, GitHub Actions artifact) and install via SideStore rather than TestFlight. `ios-testflight.yml` stays dormant — see [dev-workflow.md](dev-workflow.md).

**Not a legal gray area, unlike the Hackintosh-VM option that was considered and rejected.** SideStore/AltStore automate Apple's own official free developer-signing mechanism (the same thing Xcode does with a free Apple ID) via non-Xcode client software — it doesn't touch Apple's macOS license the way running macOS on non-Apple hardware would. Worth remembering if this decision is ever revisited, so it isn't conflated with that rejected option.

*(Originally this entry framed the fee as "deferred until CarPlay" — superseded by the entry directly below, which drops CarPlay entirely. Kept for the SideStore reasoning, which still stands.)*

## 2026-09-22 — CarPlay dropped from scope entirely

**CarPlay is not part of this project, full stop — not deferred to a later phase, just not planned.**
Why: Louis's car doesn't have CarPlay. It was part of the original inspiration (seeing Claude/ChatGPT's CarPlay apps) but was never actually usable for his own driving setup — an oversight caught only after the CarPlay entitlement, `CarPlaySceneDelegate`, and a "Phase 6 — CarPlay" roadmap phase had already been scaffolded. All of that has been removed.
How to apply: the app is a standalone iPhone app — mounted in the car, screen unused during driving, audio through the phone's speaker or whatever Bluetooth audio the car already supports (ordinary Bluetooth audio needs no special entitlement, unlike CarPlay). This also means **the $99/year Apple Developer Program fee currently has no trigger at all** in this project's plan — not CarPlay, not TestFlight (see the entry above) — only "decide to distribute to other people" would reintroduce it, and that's not currently planned either. If a future car has CarPlay, this can be revisited, but don't build toward it speculatively until then.

## 2026-09-22 — Claude API token frugality: thinking disabled, Haiku over Sonnet

**Extended thinking is explicitly disabled on every backend request, and the default model is Haiku 4.5, not Sonnet 5.**
Why: Louis has a limited Anthropic token budget and asked to avoid waste. Live testing during Phase 0 verification showed Sonnet 5 burning 184–273 "thinking" tokens (billed as output tokens) on trivially simple requests like "remind me to call the dentist tomorrow at 3pm" — thinking is on by default for that model unless explicitly turned off. Neither thinking depth nor Sonnet-level reasoning is needed for this app's actual job: routing to a tool or giving a short spoken reply.
How to apply: `backend/src/claude.ts` sets `thinking: { type: "disabled" }` and `MODEL = "claude-haiku-4-5-20251001"`. Don't reintroduce Sonnet or re-enable thinking as a default without discussing the cost tradeoff first — a specific request type turning out to need deeper reasoning is a reason to revisit, not a reason to silently upgrade the default. Also: avoid unnecessary live test calls against the real Claude API going forward (use `npm run typecheck` and code review to verify changes where possible) — that's what surfaced this issue in the first place. See [[feedback-api-frugality]].

## 2026-09-22 — Pre-install risk assessment: backend auth + voice-pipeline bug fixes

**Before HandsFree was ever installed on Louis's actual phone via SideStore, did a full manual code review and fixed five real issues** — most importantly, the backend had zero authentication despite being a public URL proxying to a paid API (direct conflict with the token-frugality decision above). Full findings, fixes, and the accepted/deferred lower-severity items: [risk-assessment.md](risk-assessment.md).
Why: Louis explicitly asked for a comprehensive risk assessment before testing on his real daily-driver device, not just verbal reassurance.
How to apply: treat [risk-assessment.md](risk-assessment.md) as a living document, not a one-time checklist — re-run a review like it before any future change to the voice pipeline, the backend's auth/cost model, or before Phase 5 (wake word) removes the push-to-talk button as the point where a human decides to start a request.

## 2026-09-22 — Version numbers, so Louis can tell installed builds apart

**The installed app shows `vX.Y (build)` on-screen (`ContentView`), and each CI-built `.ipa`/artifact is named with the same version, instead of always being called the same static filename.**
Why: after the first on-device test needed a same-named-file replace-and-hope-it's-the-new-one reinstall (via OneDrive, since GitHub's mobile artifact download was unreliable), Louis asked for a way to confirm on his phone which build he actually has, rather than trusting the filename he happened to sideload.
How to apply: bump `MARKETING_VERSION` in `ios/project.yml` for each build worth distinguishing (this install is `1.0`) — `CURRENT_PROJECT_VERSION` (the build number) can increment more freely for same-version iterations. `ios-sideload-build.yml` reads both from the built `Info.plist` to name the `.ipa`/artifact — don't hardcode a filename there again.

## 2026-09-22 — First real on-device test: UX and diagnostics overhaul

**After the first live test on Louis's phone, added: a real press-and-hold talk button (was a tap-to-toggle mislabeled "Hold to talk"), a live partial-transcript display while listening, a first-run onboarding screen that requests permissions up front, a Settings screen showing permission status with a link to iOS Settings, and an on-screen timestamped diagnostic log covering every step of a turn (listening start/stop, what was heard, request sent, response received, tool calls, TTS start/finish).**
Why: Claude has no Mac/iOS Simulator access and cannot run or click through the app itself — every test cycle depends on Louis describing what happened. The diagnostic log exists specifically so a test can be diagnosed by reading it, not by guessing over chat. The button/onboarding/live-transcript fixes came directly from what that first test surfaced: the button's real behavior (tap-toggle) didn't match its label ("Hold to talk"), and there was no feedback at all that speech was being captured — `onPartialTranscript` had been wired up in the recognizer since Phase 1 but never actually displayed anywhere.
How to apply: when adding new behavior to the voice pipeline, log it via `ConversationStore.log(_:)` rather than assuming a future test will surface problems through symptoms alone. Also added `AVAudioSession` interruption handling (e.g. an incoming call) in `SpeechTranscriber` while in this area — the same "stuck listening forever" failure class as the cancel()/endAudio() bug, just a different trigger.
