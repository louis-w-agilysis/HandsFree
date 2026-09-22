import AppIntents

/// Donated so `"Hey Siri, ask HandsFree to…"` and Shortcuts automations (e.g.
/// auto-launch on Bluetooth car-audio connect) can open straight into a conversation.
/// This is the well-supported direction of App Intents — Siri calling
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
    // `query` is deliberately NOT referenced in the phrase below: App Shortcuts
    // phrases only accept AppEntity/AppEnum parameters (a fixed vocabulary Siri can
    // match offline), not free-text String. The phrase just opens the app; the actual
    // question is captured afterwards through the normal voice pipeline.
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskHandsFreeIntent(),
            phrases: ["Ask \(.applicationName) a question"],
            shortTitle: "Ask HandsFree",
            systemImageName: "mic.fill"
        )
    }
}
