import Foundation

/// Routes a `ToolCall` from Claude to the handler that implements it, then reports the
/// result back so `ConversationStore` can send it to Claude as the next turn. Each case
/// here must have a matching entry in backend/src/tools/schema.ts — see
/// docs/architecture.md for the per-integration notes on how each of these is actually
/// implemented (App Intents alone isn't enough for cross-app control; several go
/// through first-party frameworks like EventKit/MapKit instead).
final class ToolDispatcher {
    private let reminders = AddReminderHandler()
    private let directions = GetDirectionsHandler()

    func dispatch(_ toolCall: ToolCall) {
        switch toolCall.name {
        case "add_reminder":
            reminders.handle(toolCall)
        case "get_directions":
            directions.handle(toolCall)
        default:
            assertionFailure("Unhandled tool call: \(toolCall.name) — add a handler or remove it from schema.ts")
        }
    }
}
