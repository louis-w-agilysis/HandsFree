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
    @Published private(set) var isSpeaking = false
    /// Live partial transcript while listening — the actual fix for "I have no idea
    /// if it's registering what I'm saying": this was always being produced by
    /// SFSpeechRecognizer, just never displayed anywhere.
    @Published private(set) var liveTranscript = ""
    /// Timestamped event log covering every step of a turn, so a test can be
    /// diagnosed by reading this rather than guessing over chat. Also relayed to the
    /// backend (see `DiagnosticsReporter`) so it can be read remotely, since Claude
    /// has no way to see this screen directly.
    @Published private(set) var debugLog: [String] = []

    /// How many recent turns to send as context on each request. Every message sends
    /// its full history to Claude, so without a cap, a long session's token cost (and
    /// therefore spend) grows unbounded — see docs/risk-assessment.md.
    private let maxHistoryTurns = 20
    private let maxDebugLogLines = 300

    private let claudeClient = ClaudeClient()
    private let transcriber: SpeechTranscribing = OnDeviceSpeechTranscriber()
    private let synthesizer: SpeechSynthesizing = OnDeviceSpeechSynthesizer()
    private let toolDispatcher = ToolDispatcher()
    private let diagnosticsReporter = DiagnosticsReporter()

    private var inProgressAssistantText = ""

    init() {
        transcriber.onPartialTranscript = { [weak self] text in
            Task { @MainActor in
                self?.liveTranscript = text
            }
        }
        transcriber.onFinalTranscript = { [weak self] text in
            Task { @MainActor in
                guard let self else { return }
                self.isListening = false
                self.liveTranscript = ""
                guard !text.isEmpty else {
                    self.log("Heard nothing")
                    return
                }
                self.log("Heard: \"\(text)\"")
                self.send(text)
            }
        }
        transcriber.onError = { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.isListening = false
                self.liveTranscript = ""
                self.log("Speech recognition error: \(error.localizedDescription)")
                self.turns.append(
                    ConversationTurn(role: .assistant, text: "Didn't catch that — try again? (\(error.localizedDescription))")
                )
            }
        }
        synthesizer.onSpeechStart = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.isSpeaking = true
                self.log("Speaking response aloud")
            }
        }
        synthesizer.onSpeechFinish = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.isSpeaking = false
                self.log("Finished speaking")
            }
        }
    }

    /// Called on press-down. Real press-and-hold, not a tap-to-toggle — the button
    /// used to be labeled "Hold to talk" but actually toggled on tap, which was
    /// confusing and didn't match what it said.
    func beginPressToTalk() {
        guard !isProcessing, !isListening else { return }
        do {
            try transcriber.startTranscribing()
            isListening = true
            liveTranscript = ""
            log("Listening started")
        } catch {
            log("Couldn't start listening: \(error.localizedDescription)")
            turns.append(ConversationTurn(role: .assistant, text: "Couldn't start listening: \(error.localizedDescription)"))
        }
    }

    /// Called on release.
    func endPressToTalk() {
        guard isListening else { return }
        transcriber.stopTranscribing()
        log("Listening stopped, finalizing…")
    }

    func send(_ text: String) {
        guard !isProcessing else { return }

        turns.append(ConversationTurn(role: .user, text: text))
        inProgressAssistantText = ""
        isProcessing = true
        log("Sending to Claude…")

        let recentTurns = Array(turns.suffix(maxHistoryTurns))
        var toolResults: [String] = []

        Task { @MainActor in
            defer { isProcessing = false }
            do {
                try await claudeClient.converse(
                    messages: recentTurns,
                    onTextDelta: { [weak self] delta in
                        self?.inProgressAssistantText += delta
                    },
                    onToolCall: { [weak self] toolCall in
                        guard let self else { return }
                        self.log("Tool call: \(toolCall.name) \(toolCall.input)")
                        let result = await self.toolDispatcher.dispatch(toolCall)
                        self.log("Tool result: \(result)")
                        toolResults.append(result)
                    }
                )
                log("Response received (\(inProgressAssistantText.count) chars, \(toolResults.count) tool call(s))")
                finishAssistantTurn(toolResults: toolResults)
            } catch {
                // Speak/show whatever text (and any tool results) had already
                // completed before the error, rather than silently discarding a
                // partial answer the user was already hearing.
                log("Request failed: \(error.localizedDescription)")
                finishAssistantTurn(toolResults: toolResults)
                turns.append(ConversationTurn(role: .assistant, text: "Something went wrong: \(error.localizedDescription)"))
            }
        }
    }

    /// Always produces something the user hears — this used to only speak
    /// `inProgressAssistantText`, so a response that was *only* a tool call (Claude
    /// often doesn't add accompanying text — see docs/risk-assessment.md) went
    /// completely silent: no reminder feedback, no error, nothing. Tool results are
    /// appended to whatever text Claude did send, not sent back to Claude for a more
    /// natural reply — that's the still-open TODO in docs/architecture.md.
    private func finishAssistantTurn(toolResults: [String] = []) {
        var text = inProgressAssistantText
        if !toolResults.isEmpty {
            if !text.isEmpty { text += " " }
            text += toolResults.joined(separator: " ")
        }
        guard !text.isEmpty else {
            log("(empty response — nothing to speak)")
            turns.append(ConversationTurn(role: .assistant, text: "(no response)"))
            return
        }
        turns.append(ConversationTurn(role: .assistant, text: text))
        synthesizer.speak(text)
        inProgressAssistantText = ""
    }

    private func log(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        debugLog.append("[\(timestamp)] \(message)")
        if debugLog.count > maxDebugLogLines {
            debugLog.removeFirst(debugLog.count - maxDebugLogLines)
        }
        diagnosticsReporter.report(debugLog)
    }
}
