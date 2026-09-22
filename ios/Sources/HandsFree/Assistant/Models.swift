import Foundation

enum ConversationRole {
    case user
    case assistant
}

struct ConversationTurn: Identifiable {
    let id = UUID()
    let role: ConversationRole
    let text: String
}

/// Mirrors a `tool_use` block from Claude's response — see backend/src/tools/schema.ts
/// for the tool definitions this must stay in sync with.
struct ToolCall {
    let id: String
    let name: String
    let input: [String: Any]
}
