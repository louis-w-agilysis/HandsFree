import AVFoundation

/// Speaks text out loud. `AVSpeechSynthesizer`-backed by default (on-device, fast,
/// works offline) — see docs/architecture.md for why that's the default over a
/// higher-quality cloud voice, and why this is behind a protocol so that can change
/// per response later without touching `ConversationStore`.
protocol SpeechSynthesizing: AnyObject {
    /// Lets callers confirm TTS actually started/finished playing, rather than just
    /// assuming `speak(_:)` produced audible sound — useful for diagnostics when
    /// "I don't hear anything" could mean several different things went wrong.
    var onSpeechStart: (() -> Void)? { get set }
    var onSpeechFinish: (() -> Void)? { get set }

    func speak(_ text: String)
    func stopSpeaking()
}

final class OnDeviceSpeechSynthesizer: NSObject, SpeechSynthesizing, AVSpeechSynthesizerDelegate {
    var onSpeechStart: (() -> Void)?
    var onSpeechFinish: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onSpeechStart?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onSpeechFinish?()
    }
}
