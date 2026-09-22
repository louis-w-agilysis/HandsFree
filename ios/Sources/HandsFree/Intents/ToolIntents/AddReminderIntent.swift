import EventKit

/// Implements the `add_reminder` tool (backend/src/tools/schema.ts) via EventKit — a
/// first-party framework, no cross-app App Intents invocation needed. Returns a result
/// string so the user always hears whether it actually worked, rather than the app
/// going silent on a tool call — see docs/risk-assessment.md.
final class AddReminderHandler {
    private let store = EKEventStore()

    func handle(_ toolCall: ToolCall) async -> String {
        guard let title = toolCall.input["title"] as? String, !title.isEmpty else {
            return "Couldn't add a reminder — no title was given."
        }

        let granted: Bool
        do {
            granted = try await store.requestFullAccessToReminders()
        } catch {
            return "Couldn't get Reminders access: \(error.localizedDescription)"
        }
        guard granted else {
            return "Reminders access isn't allowed — enable it in Settings to use this."
        }

        guard let calendar = store.defaultCalendarForNewReminders() else {
            return "No Reminders list is available to save to."
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = calendar

        if let dueString = toolCall.input["due_at_iso8601"] as? String,
           let dueDate = ISO8601DateFormatter().date(from: dueString) {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }

        do {
            try store.save(reminder, commit: true)
            return "Added reminder: \(title)."
        } catch {
            return "Couldn't save the reminder: \(error.localizedDescription)"
        }
    }
}
