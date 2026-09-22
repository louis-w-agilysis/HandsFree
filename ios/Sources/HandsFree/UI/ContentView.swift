import SwiftUI

/// Phone-screen UI. Deliberately minimal — this app is designed to be used without
/// looking at the screen (see docs/architecture.md); the screen exists for setup,
/// debugging, and the moments before/after driving, not as the primary interface.
struct ContentView: View {
    @EnvironmentObject private var conversation: ConversationStore
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @State private var showSettings = false
    @State private var showDiagnostics = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                List(conversation.turns) { turn in
                    Text(turn.text)
                        .font(.body)
                        .foregroundStyle(turn.role == .user ? .primary : .secondary)
                }
                .listStyle(.plain)

                if conversation.isListening {
                    Text(conversation.liveTranscript.isEmpty ? "…" : conversation.liveTranscript)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                talkButton

                DisclosureGroup("Diagnostics", isExpanded: $showDiagnostics) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(conversation.debugLog.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                }
            }
            .padding()
            .navigationTitle("HandsFree \(versionLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack { SettingsView() }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
            }
        }
    }

    // Real press-and-hold, not a tap-to-toggle Button — SwiftUI's Button only fires
    // on release, so it can't distinguish "press down" from "tap"; DragGesture with
    // zero minimum distance is the standard way to detect both edges.
    private var talkButton: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(buttonColor)
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: buttonIcon)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                )
                .opacity(conversation.isProcessing ? 0.5 : 1)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in conversation.beginPressToTalk() }
                        .onEnded { _ in conversation.endPressToTalk() }
                )
                .allowsHitTesting(!conversation.isProcessing)

            Text(buttonLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var buttonColor: Color {
        if conversation.isProcessing { return .gray }
        return conversation.isListening ? .red : .accentColor
    }

    private var buttonLabel: String {
        if conversation.isProcessing { return "Thinking…" }
        if conversation.isSpeaking { return "Speaking…" }
        return conversation.isListening ? "Release when done" : "Press & hold to talk"
    }

    private var buttonIcon: String {
        if conversation.isProcessing { return "ellipsis" }
        return conversation.isListening ? "waveform" : "mic.fill"
    }

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "v\(version)"
    }
}

#Preview {
    ContentView()
        .environmentObject(ConversationStore())
}
