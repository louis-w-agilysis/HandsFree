# Development workflow (no Mac, free)

Louis doesn't own a Mac — only device access is an iPhone 15 Pro, for installing the finished app, not for development. This doc is the concrete answer to "how do we build an iOS app under that constraint, without paying anything beyond Claude API usage" — see [decisions.md](decisions.md) for the reasoning behind each choice below.

## The loop

```
Edit Swift in this Windows/Claude Code environment (as now)
   → git push to a public GitHub repo
   → GitHub Actions (macOS runner, free — public repo)
        - every push: plain compile check (ios-build.yml), no signing needed
        - on demand: unsigned device .ipa artifact (ios-sideload-build.yml)
   → download the .ipa artifact, install via SideStore
   → running on the iPhone 15 Pro — no cable, no Mac, no Apple fee
```

**SideStore** is a free-Apple-ID sideloading tool (a fork of AltStore). It uses Apple's own official free developer-signing mechanism — the same thing Xcode does with a free Apple ID — just via non-Xcode client software. That distinction matters: this is *not* the legal gray area a Hackintosh macOS VM would be (see [decisions.md](decisions.md)); it doesn't touch Apple's macOS license at all, it just automates the free provisioning Apple already offers every developer.

- **One-time setup only needs this PC** (SideStore's docs: [docs.sidestore.io](https://docs.sidestore.io)) — after installing SideStore itself onto the phone, it self-refreshes the 7-day free certificate on-device via a local VPN trick. No computer or cable needed again after that.
- Free-tier limits that don't matter here: capped at 3 sideloaded apps at once (we need 1), ~10 new app ID registrations/week (a non-issue once the bundle ID is stable), no push notifications or in-app purchases (this app needs neither).

## Why the Apple Developer Program fee isn't needed at all right now

The only thing that ever required it was the CarPlay entitlement, and CarPlay is out of scope — Louis's car doesn't have it, and the project doesn't need it to deliver hands-free voice control (see [decisions.md](decisions.md)). Without that, there's currently no planned reason to pay Apple anything: App Intents, Siri donation, EventKit, MapKit, MusicKit, and on-device speech frameworks all work fine under a free Apple ID. The only thing that would reintroduce the fee is deciding to distribute the app to other people (App Store or TestFlight-for-others) — already deferred by the "personal use first" decision, and not currently planned.

## The three CI workflows

- [`.github/workflows/ios-build.yml`](../.github/workflows/ios-build.yml) — runs on every push, builds for the Simulator, no signing. Pure compile-check. Works today.
- [`.github/workflows/ios-sideload-build.yml`](../.github/workflows/ios-sideload-build.yml) — manually triggered, builds an **unsigned device-target .ipa** and uploads it as a workflow artifact. Download it from the Actions run and hand it to SideStore to install on the phone. This is the standing release path.
- [`.github/workflows/ios-testflight.yml`](../.github/workflows/ios-testflight.yml) — manually triggered, archives/signs/uploads to TestFlight. **Inactive** — kept scaffolded in case the "personal use only" decision is ever revisited, but needs Apple Developer Program secrets configured first (see the comment at the top of that file), and there's no current plan to do that.

## When you'll still need a real (or rented) Mac

- Interactive debugging — breakpoints, the iOS Simulator UI — none of that is possible through CI logs or SideStore alone.
- For those rare cases, renting a cloud Mac by the hour (e.g. Scaleway, ~€0.11/hr) is cheap enough to treat as an occasional tool rather than something to set up permanently.

## Setup checklist (your side)

1. Create an empty **public** repo on GitHub (no README/license/gitignore — this repo already has them) and share the URL so it can be pushed here.
2. Install SideStore following [docs.sidestore.io](https://docs.sidestore.io) — one-time PC-based setup, free Apple ID.
3. When `ios-sideload-build.yml` produces an .ipa, download it from the GitHub Actions run and install via SideStore.
4. Not currently needed: Apple Developer Program enrollment ($99/year) and the secrets `ios-testflight.yml` needs — only relevant if the personal-use decision changes.
