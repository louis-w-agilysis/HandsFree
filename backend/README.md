# backend

A thin Cloudflare Worker that holds the Anthropic API key and proxies the iOS app's conversation to Claude. See [../docs/architecture.md](../docs/architecture.md) for why it exists and how it fits together.

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

## Deploying

```
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY
npm run deploy
```
