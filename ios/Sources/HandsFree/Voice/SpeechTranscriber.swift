import Foundation

/// Streams microphone audio to on-device speech-to-text. See docs/architecture.md —
/// this is deliberately a protocol so the app doesn't depend directly on WhisperKit vs.
/// Apple's SpeechAnalyzer; that choice can be made (and changed) in one place.
protocol SpeechTranscribing: AnyObject {
    /// Called with successive partial transcripts as the user speaks, then a final
    /// transcript once they stop.
    var onPartialTranscript: ((String) -> Void)? { get set }
    var onFinalTranscript: ((String) -> Void)? { get set }

    func startTranscribing() throws
    func stopTranscribing()
}

/// Placeholder until WhisperKit or SpeechAnalyzer is wired in — see ios/README.md.
final class UnimplementedSpeechTranscriber: SpeechTranscribing {
    var onPartialTranscript: ((String) -> Void)?
    var onFinalTranscript: ((String) -> Void)?

    func startTranscribing() throws {
        throw SpeechTranscriberError.notImplemented
    }

    func stopTranscribing() {}
}

enum SpeechTranscriberError: Error {
    case notImplemented
}
