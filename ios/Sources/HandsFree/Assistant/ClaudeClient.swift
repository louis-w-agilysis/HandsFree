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

    func converse(
        messages: [ConversationTurn],
        onTextDelta: @escaping (String) -> Void,
        onToolCall: @escaping (ToolCall) -> Void
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

        // TODO (Phase 1): parse the SSE stream (`event: content_block_delta`, etc.)
        // and call onTextDelta/onToolCall as events arrive. Left unimplemented until
        // the backend round trip itself is verified (docs/roadmap.md, Phase 0).
        for try await _ in bytes.lines {
            // placeholder — see TODO above
        }
    }
}

enum ClaudeClientError: Error {
    case badResponse
}
