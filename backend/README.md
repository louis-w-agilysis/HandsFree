# backend

A thin Cloudflare Worker that holds the Anthropic API key and proxies the iOS app's conversation to Claude. See [../docs/architecture.md](../docs/architecture.md) for why it exists and how it fits together.

**Deployed** at `https://handsfree-backend.louis-woolsey2.workers.dev` — this is what the iOS app talks to by default. Model is Haiku 4.5 with extended thinking disabled (see [../docs/decisions.md](../docs/decisions.md), token-frugality entry) — keep that in mind before changing `src/claude.ts`.

## Setup

```
npm install
cp .dev.vars.example .dev.vars   # then fill in your real ANTHROPIC_API_KEY
npm run dev
```

This starts a local Worker (via `wrangler dev`) that works on Windows/macOS/Linux — no Xcode required, unlike the `ios/` half of this repo.

## Endpoint

`POST /converse`

Request body:

```json
{
  "messages": [
    { "role": "user", "content": "what's a good podcast episode to start" }
  ]
}
```

Streams back Claude's response as server-sent events, including any `tool_use` blocks — the Worker does not execute tools itself (it has no access to the phone); the iOS app is responsible for executing the tool call and sending the result back in the next request. See `src/tools/schema.ts` for the current tool definitions, and `src/claude.ts` for the Anthropic API call.

## Redeploying

Already deployed and authenticated on this machine — after changing `src/`, just run:

```
npm run deploy
```

(`npx wrangler login` and `npx wrangler secret put ANTHROPIC_API_KEY` only needed again if credentials/the account change.)
