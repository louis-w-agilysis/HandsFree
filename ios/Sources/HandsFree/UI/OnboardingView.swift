import AVFoundation
import Speech
import SwiftUI

/// Shown once, before first use — requests microphone and speech-recognition
/// permission up front with an explanation, rather than lazily prompting the first
/// time the user presses the talk button with no context for why.
struct OnboardingView: View {
    let onDone: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("HandsFree needs two permissions")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                Label("Microphone — to hear you", systemImage: "mic.fill")
                Label("Speech Recognition — to transcribe what you say, entirely on-device", systemImage: "waveform")
            }
            .padding()

            Spacer()

            Button(action: requestPermissions) {
                Text(isRequesting ? "Requesting…" : "Grant Permissions")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
            .padding(.horizontal)

            Text("You can review or change these later from the gear icon.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .padding()
    }

    private func requestPermissions() {
        isRequesting = true
        SFSpeechRecognizer.requestAuthorization { _ in
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
                DispatchQueue.main.async {
                    isRequesting = false
                    onDone()
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onDone: {})
}
