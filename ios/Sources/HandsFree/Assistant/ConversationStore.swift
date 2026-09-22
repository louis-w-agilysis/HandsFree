import Foundation

/// Owns conversation state and wires together Voice/ (listening + speaking) and
/// Intents/ (executing tool calls) around the Claude client. See docs/architecture.md
/// for why these modules don't talk to each other directly.
@MainActor
final class ConversationStore: ObservableObject {
    @Published private(set) var turns: [ConversationTurn] = []
    @Published private(set) var isListening = false

    private let claudeClient = ClaudeClient()
    private let transcriber: SpeechTranscribing = UnimplementedSpeechTranscriber()
    private let synthesizer: SpeechSynthesizing = OnDeviceSpeechSynthesizer()
    private let toolDispatcher = ToolDispatcher()

    /// Phase 1 entry point (push-to-talk). Wake-word activation (Phase 5) will call
    /// the same `send(_:)` once it has a final transcript, rather than duplicating
    /// this flow.
    func togglePushToTalk() {
        isListening.toggle()
        // TODO (Phase 1): start/stop `transcriber`, call `send(_:)` with the final
        // transcript.
    }

    func send(_ text: String) {
        turns.append(ConversationTurn(role: .user, text: text))

        Task {
            do {
                try await claudeClient.converse(
                    messages: turns,
                    onTextDelta: { [weak self] delta in
                        self?.appendAssistantDelta(delta)
                    },
                    onToolCall: { [weak self] toolCall in
                        self?.toolDispatcher.dispatch(toolCall)
                    }
                )
            } catch {
                turns.append(ConversationTurn(role: .assistant, text: "Something went wrong: \(error)"))
            }
        }
    }

    private func appendAssistantDelta(_ delta: String) {
        // TODO (Phase 1): accumulate deltas into the in-progress turn and speak the
        // completed sentence via `synthesizer.speak(_:)` as it finishes, rather than
        // waiting for the whole response.
        turns.append(ConversationTurn(role: .assistant, text: delta))
    }
}
