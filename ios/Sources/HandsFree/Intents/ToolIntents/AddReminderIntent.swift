import EventKit

/// Implements the `add_reminder` tool (backend/src/tools/schema.ts) via EventKit —
/// a first-party framework, no cross-app App Intents invocation needed. See
/// docs/architecture.md: this is one of the lower-risk Phase 2 integrations.
final class AddReminderHandler {
    private let store = EKEventStore()

    func handle(_ toolCall: ToolCall) {
        guard let title = toolCall.input["title"] as? String else { return }

        // TODO (Phase 2): request EKEventStore access, create and save an EKReminder
        // with `title`, and parse `due_at_iso8601` into a due-date component if present.
        _ = title
    }
}
