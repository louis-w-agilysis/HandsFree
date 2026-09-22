# Research: competitive landscape (as of Sept 2026)

Captured from a brainstorming session on 2026-09-22. Re-verify anything load-bearing before relying on it — this is a fast-moving space and some of these features shipped only weeks before this was written.

## Existing voice AI in cars / hands-free contexts

- **ChatGPT on CarPlay** (iOS 26.4+): voice-only, hands-free, no wake word (must open manually), cannot control vehicle or iPhone functions. [WinBuzzer](https://winbuzzer.com/2026/04/01/openai-chatgpt-apple-carplay-voice-hands-free-xcxwbn/)
- **Claude on CarPlay**: answers hands-free questions, trip planning, brainstorming — same limitation, cannot control the vehicle or iPhone. [Kingy AI](https://kingy.ai/news/claude-apple-carplay-ai-chatbots-ios-27/)
- **Grok, Perplexity, Meta AI** have also shipped CarPlay chatbot apps in the same window. [9to5Mac](https://9to5mac.com/2026/08/29/apple-carplay-gaining-a-new-ai-chatbot-app-before-siri-ai-arrives/)
- **The common thread**: every major assistant on CarPlay right now is conversational-only. None of them act on your behalf. That's the gap.

## The App Intents path (this is the key enabler)

- Apple opened a **new CarPlay entitlement category for "voice-based conversational apps"** in Feb 2026 (developer guide update; requestable from iOS 26.4+). Apps in this category must launch directly into voice interaction and can both answer *and perform actions*. Apple reviews/approves each request. [AppleInsider](https://appleinsider.com/articles/26/02/18/ai-agents-are-coming-to-carplay-but-theyre-not-getting-the-keys)
- **App Intents is now the universal contract for agentic access to an app on iOS.** Apple deprecated SiriKit in its favor (2–3 year support window). Any app that wants to be callable by Siri, Shortcuts, or (per Apple's 2026 framing) other agentic flows needs to expose App Intents. [ecorpit.com](https://ecorpit.com/ios-27-app-store-ai-agents-app-intents-developer-strategy-2026/)
- **Important nuance / open risk**: App Intents is mediated by the system (Siri, Shortcuts, Spotlight) — there is no confirmed public API for one third-party app to directly invoke another third-party app's App Intents programmatically. So "control Spotify" in practice likely means: Spotify's own iOS SDK / deep links, or running a Shortcuts workflow via `shortcuts://run-shortcut`, or MusicKit/MPMusicPlayerController for Apple Music, or EventKit for reminders/calendar, or MapKit for directions — not a generic "call any app's intent" mechanism. **This needs per-integration research before Phase 2+** (see [architecture.md](architecture.md)).
- Claude already ships a basic **"Ask Claude" App Intent** — usable from Siri, Spotlight, and Shortcuts today. Useful as a reference implementation, and as a fallback building block. [Claude Help Center](https://support.claude.com/en/articles/10263469-use-claude-app-intents-shortcuts-and-widgets-on-ios)
- iOS 27's Siri Extensions (choose Claude/ChatGPT/Gemini as Siri's own backend) is **not** a hook a third-party app can plug into — that's Apple/Siri choosing a provider for its own first-party experience, not an integration point for us.

## Hardware cautionary tale

- **Rabbit R1** and **Humane AI Pin** both tried to ship bespoke hardware with an LLM "large action model." Both were panned — sluggish, bad battery, missing basics like timers/alarms. [Decrypt](https://decrypt.co/228146/rabbit-r1-ai-reviews-gadget-hardware), [TechRadar](https://www.techradar.com/computing/artificial-intelligence/with-the-humane-ai-pin-now-dead-what-does-the-rabbit-r1-need-to-do-to-survive)
- **Lesson**: build software on the phone people already carry (and the CarPlay head unit already in their car). Don't reinvent hardware.

## Voice pipeline building blocks

- **WhisperKit** / Apple's **SpeechAnalyzer** (new in iOS 26): on-device streaming transcription, <200ms first-word latency reported for WhisperKit large-v3-turbo on iPhone 15 Pro. No 1-minute cap, automatic language detection, fully on-device. [picovoice.ai](https://picovoice.ai/blog/ios-speech-recognition/)
- **Picovoice Porcupine** (or Sensory): on-device wake-word detection, no audio leaves the device. [Picovoice](https://picovoice.ai/blog/complete-guide-to-wake-word/)
- **Claude API**: streaming + tool use gets sub-500ms round trips reported for Claude 3.5 Sonnet-class models; streaming lets you start executing a tool call before the full response finishes generating. [platform.claude.com](https://platform.claude.com/docs/en/build-with-claude/streaming)

## Legal note (driving-specific)

- US hands-free laws vary by state, but **voice-activated, zero-touch use is permitted almost everywhere** that regulates handheld phone use. A couple of states (e.g. Massachusetts) explicitly allow a single tap to activate voice mode. Designing for **wake-word activation** (no touch at all) is the safest target across jurisdictions, not just a UX nicety. [Mass.gov](https://www.mass.gov/info-details/hands-free-law-0), [Wikipedia: Restrictions on cell phone use while driving in the United States](https://en.wikipedia.org/wiki/Restrictions_on_cell_phone_use_while_driving_in_the_United_States)
