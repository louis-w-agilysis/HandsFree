import AppIntents

/// Donated so `"Hey Siri, ask HandsFree to…"` and Shortcuts automations (e.g.
/// auto-launch on CarPlay connect, see docs/roadmap.md Phase 6) can open straight into
/// a conversation. This is the well-supported direction of App Intents — Siri calling
/// into *this* app — as opposed to this app calling into others (see the tool-call
/// handlers in ToolIntents/, and the open risk noted in docs/architecture.md).
struct AskHandsFreeIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask HandsFree"
    static var description = IntentDescription("Start a conversation with HandsFree.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "What do you want to ask?")
    var query: String?

    func perform() async throws -> some IntentResult {
        // TODO (Phase 1): hand `query` off to ConversationStore.send(_:) once there's
        // a shared entry point reachable from both the app and the intent.
        return .result()
    }
}

struct HandsFreeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskHandsFreeIntent(),
            phrases: ["Ask \(.applicationName) to \(\.$query)"],
            shortTitle: "Ask HandsFree",
            systemImageName: "mic.fill"
        )
    }
}
