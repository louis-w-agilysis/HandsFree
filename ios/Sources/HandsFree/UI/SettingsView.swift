import AVFoundation
import Speech
import SwiftUI

/// Shows current permission status and links to iOS Settings to change them — an app
/// can't re-prompt for a permission the user already denied, Settings is the only way.
struct SettingsView: View {
    var body: some View {
        Form {
            Section("Permissions") {
                LabeledContent("Microphone", value: microphoneStatus)
                LabeledContent("Speech Recognition", value: speechStatus)

                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: versionLabel)
            }
        }
        .navigationTitle("Settings")
    }

    private var microphoneStatus: String {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return "Allowed"
        case .denied: return "Denied — see iOS Settings"
        case .undetermined: return "Not yet asked"
        @unknown default: return "Unknown"
        }
    }

    private var speechStatus: String {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return "Allowed"
        case .denied: return "Denied — see iOS Settings"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not yet asked"
        @unknown default: return "Unknown"
        }
    }

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
