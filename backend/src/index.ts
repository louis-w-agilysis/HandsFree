import { streamConverse, type ConverseMessage } from "./claude";

export interface Env {
  ANTHROPIC_API_KEY: string;
  CLIENT_SHARED_SECRET: string;
  DIAGNOSTICS: KVNamespace;
}

interface ConverseRequestBody {
  messages: ConverseMessage[];
}

interface LogRequestBody {
  entries: string[];
}

const DIAGNOSTICS_KEY = "latest";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (!env.ANTHROPIC_API_KEY || !env.CLIENT_SHARED_SECRET) {
      return new Response("Server misconfigured", { status: 500 });
    }

    // This URL is public (it's in a public GitHub repo) and proxies to a paid API
    // with no rate limiting -- without this check, anyone who finds it could run up
    // real charges, or read/flood the diagnostics log. See docs/risk-assessment.md.
    if (request.headers.get("Authorization") !== `Bearer ${env.CLIENT_SHARED_SECRET}`) {
      return new Response("Unauthorized", { status: 401 });
    }

    const url = new URL(request.url);

    if (url.pathname === "/converse" && request.method === "POST") {
      return handleConverse(request, env);
    }
    if (url.pathname === "/log" && request.method === "POST") {
      return handleLogWrite(request, env);
    }
    if (url.pathname === "/log" && request.method === "GET") {
      return handleLogRead(env);
    }

    return new Response("Not found", { status: 404 });
  },
};

async function handleConverse(request: Request, env: Env): Promise<Response> {
  let body: ConverseRequestBody;
  try {
    body = await request.json();
  } catch {
    return new Response("Invalid JSON body", { status: 400 });
  }

  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return new Response("`messages` must be a non-empty array", { status: 400 });
  }

  const anthropicResponse = await streamConverse(env.ANTHROPIC_API_KEY, body.messages);

  // Pass the SSE stream straight through to the iOS client.
  return new Response(anthropicResponse.body, {
    status: anthropicResponse.status,
    headers: {
      "content-type": "text/event-stream",
      "cache-control": "no-cache",
    },
  });
}

// Relays the phone's on-screen diagnostic log here so it can be read with GET /log
// without the user needing to relay anything manually -- see docs/decisions.md. Single
// fixed key: one user, one phone, no need for anything fancier yet. The app sends its
// whole current (already-capped) log array on every entry, so this is always a full
// snapshot, not something that needs incremental-append handling.
async function handleLogWrite(request: Request, env: Env): Promise<Response> {
  let body: LogRequestBody;
  try {
    body = await request.json();
  } catch {
    return new Response("Invalid JSON body", { status: 400 });
  }

  if (!Array.isArray(body.entries)) {
    return new Response("`entries` must be an array", { status: 400 });
  }

  await env.DIAGNOSTICS.put(
    DIAGNOSTICS_KEY,
    JSON.stringify({ entries: body.entries, updatedAt: new Date().toISOString() })
  );

  return new Response(null, { status: 204 });
}

async function handleLogRead(env: Env): Promise<Response> {
  const stored = await env.DIAGNOSTICS.get(DIAGNOSTICS_KEY);
  return new Response(stored ?? JSON.stringify({ entries: [], updatedAt: null }), {
    headers: { "content-type": "application/json" },
  });
}
