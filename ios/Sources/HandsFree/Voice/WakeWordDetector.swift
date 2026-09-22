import Foundation

/// Listens continuously for the wake word and calls `onWake` when heard. Runs entirely
/// on-device — no audio leaves the phone (see docs/decisions.md for why this matters
/// for both privacy and hands-free-law compliance).
///
/// Phase 5 (docs/roadmap.md): not used until push-to-talk (Phase 1) proves the rest of
/// the pipeline works. The intended implementation is Picovoice Porcupine; this
/// protocol exists so that choice can change without touching `ConversationStore`.
protocol WakeWordDetecting: AnyObject {
    var onWake: (() -> Void)? { get set }
    func startListening() throws
    func stopListening()
}

/// Placeholder until Porcupine (or an alternative) is integrated — see ios/README.md
/// for adding the dependency.
final class UnimplementedWakeWordDetector: WakeWordDetecting {
    var onWake: (() -> Void)?

    func startListening() throws {
        throw WakeWordError.notImplemented
    }

    func stopListening() {}
}

enum WakeWordError: Error {
    case notImplemented
}
