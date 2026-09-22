import Foundation

/// Owns conversation state and wires together Voice/ (listening + speaking) and
/// Intents/ (executing tool calls) around the Claude client. See docs/architecture.md
/// for why these modules don't talk to each other directly.
@MainActor
final class ConversationStore: ObservableObject {
    @Published private(set) var turns: [ConversationTurn] = []
    @Published private(set) var isListening = false

    private let claudeClient = ClaudeClient()
    private let transcriber: SpeechTranscribing = OnDeviceSpeechTranscriber()
    private let synthesizer: SpeechSynthesizing = OnDeviceSpeechSynthesizer()
    private let toolDispatcher = ToolDispatcher()

    private var inProgressAssistantText = ""

    init() {
        transcriber.onFinalTranscript = { [weak self] text in
            Task { @MainActor in
                self?.isListening = false
                guard !text.isEmpty else { return }
                self?.send(text)
            }
        }
    }

    /// Phase 1 entry point. Wake-word activation (Phase 5, docs/roadmap.md) will call
    /// the same `send(_:)` once it has a final transcript, rather than duplicating
    /// this flow.
    func togglePushToTalk() {
        if isListening {
            transcriber.stopTranscribing()
            isListening = false
        } else {
            do {
                try transcriber.startTranscribing()
                isListening = true
            } catch {
                turns.append(ConversationTurn(role: .assistant, text: "Couldn't start listening: \(error)"))
            }
        }
    }

    func send(_ text: String) {
        turns.append(ConversationTurn(role: .user, text: text))
        inProgressAssistantText = ""

        Task { @MainActor in
            do {
                try await claudeClient.converse(
                    messages: turns,
                    onTextDelta: { [weak self] delta in
                        self?.inProgressAssistantText += delta
                    },
                    onToolCall: { [weak self] toolCall in
                        // TODO (Phase 2+): send the tool result back to Claude as the
                        // next turn once the handlers below actually do something to
                        // report — see the open risk in docs/architecture.md.
                        self?.toolDispatcher.dispatch(toolCall)
                    }
                )
                finishAssistantTurn()
            } catch {
                turns.append(ConversationTurn(role: .assistant, text: "Something went wrong: \(error)"))
            }
        }
    }

    private func finishAssistantTurn() {
        guard !inProgressAssistantText.isEmpty else { return }
        let text = inProgressAssistantText
        turns.append(ConversationTurn(role: .assistant, text: text))
        synthesizer.speak(text)
        inProgressAssistantText = ""
    }
}
