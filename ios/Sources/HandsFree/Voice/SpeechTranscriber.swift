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

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func startTranscribing() throws {
        SFSpeechRecognizer.requestAuthorization { _ in }

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
            guard let self, let result else { return }
            if result.isFinal {
                self.onFinalTranscript?(result.bestTranscription.formattedString)
            } else {
                self.onPartialTranscript?(result.bestTranscription.formattedString)
            }
        }
    }

    func stopTranscribing() {
        guard audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }
}

enum SpeechTranscriberError: Error {
    case recognizerUnavailable
}
