import AVFoundation

/// Speaks text out loud. `AVSpeechSynthesizer`-backed by default (on-device, fast,
/// works offline) — see docs/architecture.md for why that's the default over a
/// higher-quality cloud voice, and why this is behind a protocol so that can change
/// per response later without touching `ConversationStore`.
protocol SpeechSynthesizing: AnyObject {
    func speak(_ text: String)
    func stopSpeaking()
}

final class OnDeviceSpeechSynthesizer: NSObject, SpeechSynthesizing {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
