import Foundation

/// Owns conversation state and wires together Voice/ (listening + speaking) and
/// Intents/ (executing tool calls) around the Claude client. See docs/architecture.md
/// for why these modules don't talk to each other directly.
@MainActor
final class ConversationStore: ObservableObject {
    @Published private(set) var turns: [ConversationTurn] = []
    @Published private(set) var isListening = false
    /// True from the moment a request is sent until Claude's response finishes (or
    /// errors). Guards against starting a second turn while one is already in
    /// flight — without this, two concurrent `converse()` calls would interleave
    /// their streamed text into the same `inProgressAssistantText`, producing
    /// garbled spoken output.
    @Published private(set) var isProcessing = false

    /// How many recent turns to send as context on each request. Every message sends
    /// its full history to Claude, so without a cap, a long session's token cost (and
    /// therefore spend) grows unbounded — see docs/risk-assessment.md.
    private let maxHistoryTurns = 20

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
        transcriber.onError = { [weak self] error in
            Task { @MainActor in
                self?.isListening = false
                self?.turns.append(
                    ConversationTurn(role: .assistant, text: "Didn't catch that — try again? (\(error.localizedDescription))")
                )
            }
        }
    }

    /// Phase 1 entry point. Wake-word activation (Phase 5, docs/roadmap.md) will call
    /// the same `send(_:)` once it has a final transcript, rather than duplicating
    /// this flow.
    func togglePushToTalk() {
        guard !isProcessing else { return }

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
        guard !isProcessing else { return }

        turns.append(ConversationTurn(role: .user, text: text))
        inProgressAssistantText = ""
        isProcessing = true

        let recentTurns = Array(turns.suffix(maxHistoryTurns))

        Task { @MainActor in
            defer { isProcessing = false }
            do {
                try await claudeClient.converse(
                    messages: recentTurns,
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
                // Speak/show whatever text had already streamed before the error,
                // rather than silently discarding a partial answer the user was
                // already hearing.
                finishAssistantTurn()
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
