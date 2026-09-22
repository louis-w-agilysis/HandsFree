import { streamConverse, type ConverseMessage } from "./claude";

export interface Env {
  ANTHROPIC_API_KEY: string;
  CLIENT_SHARED_SECRET: string;
}

interface ConverseRequestBody {
  messages: ConverseMessage[];
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/converse" && request.method === "POST") {
      return handleConverse(request, env);
    }

    return new Response("Not found", { status: 404 });
  },
};

async function handleConverse(request: Request, env: Env): Promise<Response> {
  if (!env.ANTHROPIC_API_KEY || !env.CLIENT_SHARED_SECRET) {
    return new Response("Server misconfigured", { status: 500 });
  }

  // This URL is public (it's in a public GitHub repo) and proxies to a paid API with
  // no rate limiting -- without this check, anyone who finds it could run up real
  // charges. See docs/risk-assessment.md.
  if (request.headers.get("Authorization") !== `Bearer ${env.CLIENT_SHARED_SECRET}`) {
    return new Response("Unauthorized", { status: 401 });
  }

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
