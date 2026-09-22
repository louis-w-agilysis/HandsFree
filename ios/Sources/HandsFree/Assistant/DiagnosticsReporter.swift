import Foundation

/// Relays the on-screen debug log to the backend's `/log` endpoint so it can be read
/// remotely (`GET /log`) without the user needing to relay anything manually — added
/// specifically because Claude has no Mac/Simulator access and can't see this screen.
/// Fire-and-forget: a failed report must never affect the app itself, so errors are
/// silently dropped rather than surfaced anywhere.
final class DiagnosticsReporter {
    private let logURL: URL
    private var currentTask: Task<Void, Never>?

    init(backendURL: URL = URL(string: "https://handsfree-backend.louis-woolsey2.workers.dev")!) {
        self.logURL = backendURL.appendingPathComponent("log")
    }

    /// Sends the full current log snapshot (already capped by the caller), replacing
    /// whatever was reported before — simpler and more robust than incremental
    /// appends, and the log is small enough (capped at a few hundred lines) that
    /// resending it whole each time is cheap.
    func report(_ entries: [String]) {
        currentTask?.cancel()
        currentTask = Task {
            var request = URLRequest(url: logURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 10
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(Secrets.clientSharedSecret)", forHTTPHeaderField: "Authorization")
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["entries": entries])
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
