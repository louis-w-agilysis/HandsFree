import SwiftUI

/// Phone-screen UI. Deliberately minimal — this app is designed to be used without
/// looking at the screen (see docs/architecture.md); the screen exists for setup,
/// debugging, and the moments before/after driving, not as the primary interface.
struct ContentView: View {
    @EnvironmentObject private var conversation: ConversationStore

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 2) {
                Text("HandsFree")
                    .font(.largeTitle.bold())
                // So it's obvious on-screen which build is actually installed,
                // rather than having to trust the filename you sideloaded.
                Text(versionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            List(conversation.turns) { turn in
                Text(turn.text)
                    .font(.body)
                    .foregroundStyle(turn.role == .user ? .primary : .secondary)
            }
            .listStyle(.plain)

            // Phase 1: push-to-talk. Replaced by wake-word activation in Phase 5
            // (see docs/roadmap.md) — this button stays as the manual fallback.
            Button(action: conversation.togglePushToTalk) {
                Label(buttonLabel, systemImage: buttonIcon)
                    .font(.title2)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(conversation.isProcessing)
        }
        .padding()
    }

    private var buttonLabel: String {
        if conversation.isProcessing { return "Thinking…" }
        return conversation.isListening ? "Listening…" : "Hold to talk"
    }

    private var buttonIcon: String {
        if conversation.isProcessing { return "ellipsis" }
        return conversation.isListening ? "waveform" : "mic.fill"
    }

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(version) (\(build))"
    }
}

#Preview {
    ContentView()
        .environmentObject(ConversationStore())
}
