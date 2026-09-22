import { tools } from "./tools/schema";

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

// Raw fetch to the Anthropic API rather than the Node SDK — keeps this dependency-free
// and avoids Workers-runtime compatibility issues with SDKs built for Node.
const MODEL = "claude-sonnet-5";

export interface ConverseMessage {
  role: "user" | "assistant";
  content: unknown;
}

const SYSTEM_PROMPT = `You are HandsFree, a voice assistant the user talks to while driving or otherwise
unable to look at their phone. Keep responses short and conversational — they will be read aloud by
text-to-speech, not displayed as text. Never ask the user to look at or touch their phone. When an action
is available as a tool, use it rather than describing how the user could do it themselves.`;

/** Streams Claude's raw SSE response straight through to the caller. */
export function streamConverse(
  apiKey: string,
  messages: ConverseMessage[]
): Promise<Response> {
  return fetch(ANTHROPIC_API_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages,
      tools,
      stream: true,
    }),
  });
}
