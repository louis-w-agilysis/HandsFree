import Foundation

/// Talks to `backend/` (never directly to the Claude API — the API key must never ship
/// inside this app bundle, see docs/architecture.md). Streams the `/converse` SSE
/// response and surfaces text deltas and tool calls as they arrive.
final class ClaudeClient {
    private let backendURL: URL

    /// Point this at your locally-running `wrangler dev` backend during development,
    /// and at the deployed Worker URL once one exists (see backend/README.md).
    init(backendURL: URL = URL(string: "http://localhost:8787")!) {
        self.backendURL = backendURL
    }

    /// `onTextDelta`/`onToolCall` are typed `@MainActor` so callers can safely touch
    /// UI state directly inside them — this function's own loop runs off-MainActor
    /// (URLSession's byte stream delivery), so each call hops back via `await`.
    func converse(
        messages: [ConversationTurn],
        onTextDelta: @escaping @MainActor (String) -> Void,
        onToolCall: @escaping @MainActor (ToolCall) -> Void
    ) async throws {
        var request = URLRequest(url: backendURL.appendingPathComponent("converse"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "messages": messages.map {
                ["role": $0.role == .user ? "user" : "assistant", "content": $0.text]
            }
        ])

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ClaudeClientError.badResponse
        }

        // Anthropic's streaming format: repeated `data: {...}` lines, each a JSON
        // event. A tool_use block arrives as a content_block_start (with id/name and
        // empty input) followed by content_block_delta events whose partial_json
        // fragments must be concatenated and parsed once the block stops.
        var pendingToolUse: (id: String, name: String, partialJSON: String)?

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst("data: ".count))
            guard let data = jsonString.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = event["type"] as? String else { continue }

            switch type {
            case "content_block_start":
                if let block = event["content_block"] as? [String: Any],
                   block["type"] as? String == "tool_use",
                   let id = block["id"] as? String,
                   let name = block["name"] as? String {
                    pendingToolUse = (id, name, "")
                }

            case "content_block_delta":
                guard let delta = event["delta"] as? [String: Any] else { continue }
                if let text = delta["text"] as? String {
                    await onTextDelta(text)
                } else if let partialJSON = delta["partial_json"] as? String, pendingToolUse != nil {
                    pendingToolUse?.partialJSON += partialJSON
                }

            case "content_block_stop":
                if let toolUse = pendingToolUse {
                    let inputData = toolUse.partialJSON.data(using: .utf8) ?? Data()
                    let input = (try? JSONSerialization.jsonObject(with: inputData) as? [String: Any]) ?? [:]
                    await onToolCall(ToolCall(id: toolUse.id, name: toolUse.name, input: input))
                    pendingToolUse = nil
                }

            default:
                break
            }
        }
    }
}

enum ClaudeClientError: Error {
    case badResponse
}
