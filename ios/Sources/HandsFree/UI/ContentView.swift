import SwiftUI

/// Phone-screen UI. Deliberately minimal — this app is designed to be used without
/// looking at the screen (see docs/architecture.md); the screen exists for setup,
/// debugging, and the moments before/after driving, not as the primary interface.
struct ContentView: View {
    @EnvironmentObject private var conversation: ConversationStore

    var body: some View {
        VStack(spacing: 24) {
            Text("HandsFree")
                .font(.largeTitle.bold())

            List(conversation.turns) { turn in
                Text(turn.text)
                    .font(.body)
                    .foregroundStyle(turn.role == .user ? .primary : .secondary)
            }
            .listStyle(.plain)

            // Phase 1: push-to-talk. Replaced by wake-word activation in Phase 5
            // (see docs/roadmap.md) — this button stays as the manual fallback.
            Button(action: conversation.togglePushToTalk) {
                Label(
                    conversation.isListening ? "Listening…" : "Hold to talk",
                    systemImage: conversation.isListening ? "waveform" : "mic.fill"
                )
                .font(.title2)
                .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(ConversationStore())
}
