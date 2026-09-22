import AVFoundation
import Speech

/// Streams microphone audio to on-device speech-to-text. See docs/architecture.md —
/// this is deliberately a protocol so the app doesn't depend directly on WhisperKit vs.
/// Apple's SpeechAnalyzer; that choice can be made (and changed) in one place.
protocol SpeechTranscribing: AnyObject {
    /// Called with successive partial transcripts as the user speaks, then a final
    /// transcript once they stop.
    var onPartialTranscript: ((String) -> Void)? { get set }
    var onFinalTranscript: ((String) -> Void)? { get set }
    /// Called instead of onFinalTranscript if recognition genuinely fails (permission
    /// denied, no speech detected, recognizer unavailable mid-session) — callers must
    /// handle this to reset any "listening" UI state, or it gets stuck indefinitely.
    var onError: ((Error) -> Void)? { get set }

    func startTranscribing() throws
    func stopTranscribing()
}

/// `SFSpeechRecognizer`-backed implementation, on-device only. Chosen over WhisperKit
/// or Apple's newer SpeechAnalyzer (iOS 26+) because it needs no extra SPM dependency
/// and its APIs exist in the SDK this project's CI currently builds against — swapping
/// it out later (once WhisperKit/SpeechAnalyzer are worth the added complexity) is a
/// one-file change thanks to the protocol above.
final class OnDeviceSpeechTranscriber: NSObject, SpeechTranscribing {
    var onPartialTranscript: ((String) -> Void)?
    var onFinalTranscript: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func startTranscribing() throws {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            SFSpeechRecognizer.requestAuthorization { _ in }
            throw SpeechTranscriberError.notAuthorized
        }

        guard let recognizer, recognizer.isAvailable else {
            throw SpeechTranscriberError.recognizerUnavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let error {
                self.tearDown()
                self.onError?(error)
                return
            }
            guard let result else { return }
            if result.isFinal {
                self.tearDown()
                self.onFinalTranscript?(result.bestTranscription.formattedString)
            } else {
                self.onPartialTranscript?(result.bestTranscription.formattedString)
            }
        }
    }

    /// Called when the user taps to stop talking. Signals end-of-speech via
    /// `endAudio()` so the recognizer finalizes whatever was actually said.
    ///
    /// This used to also call `task.cancel()` here, which was the bug: cancel() and
    /// the endAudio()-triggered finalization raced, and cancel always won, so the
    /// recognizer never got the chance to deliver a real transcript — every attempt
    /// came back as "Recognition request was canceled" instead of actual text.
    func stopTranscribing() {
        guard audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
    }

    /// Releases the request/task once the recognizer has actually finished with them
    /// (a final result or an error) — separate from `stopTranscribing()`, which only
    /// signals end-of-speech and lets recognition finish asynchronously afterward.
    private func tearDown() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request = nil
        task = nil
    }
}

enum SpeechTranscriberError: Error, LocalizedError {
    case recognizerUnavailable
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer isn't available right now."
        case .notAuthorized:
            return "Speech recognition permission not granted yet — check Settings, or try again after allowing it."
        }
    }
}
