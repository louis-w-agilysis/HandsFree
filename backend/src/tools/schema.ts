/**
 * Tool definitions passed to Claude's `tools` parameter. Each entry here must have a
 * matching handler on the iOS side (see ios/Sources/HandsFree/Intents/ToolIntents/) —
 * the backend only describes the tools, it never executes them (it has no access to
 * the phone). See docs/architecture.md for the app-to-app control caveats these
 * tools are scoped around.
 *
 * Phase 2/3 of docs/roadmap.md will add real tools here as each integration is built.
 * Keep this list in sync with what iOS actually implements — an unimplemented tool
 * will make Claude think it can do something it can't.
 */

export interface ToolDefinition {
  name: string;
  description: string;
  input_schema: {
    type: "object";
    properties: Record<string, unknown>;
    required?: string[];
  };
}

export const tools: ToolDefinition[] = [
  {
    name: "add_reminder",
    description:
      "Create a reminder in the user's Reminders app. Use when the user asks to be reminded of something.",
    input_schema: {
      type: "object",
      properties: {
        title: { type: "string", description: "The reminder text." },
        due_at_iso8601: {
          type: "string",
          description: "Optional ISO-8601 datetime for when the reminder is due.",
        },
      },
      required: ["title"],
    },
  },
  {
    name: "get_directions",
    description:
      "Start turn-by-turn directions in Maps to a destination. Use when the user asks to navigate or get directions somewhere.",
    input_schema: {
      type: "object",
      properties: {
        destination: {
          type: "string",
          description: "Address, place name, or landmark to navigate to.",
        },
      },
      required: ["destination"],
    },
  },
];
