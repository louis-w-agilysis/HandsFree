import MapKit

/// Implements the `get_directions` tool (backend/src/tools/schema.ts) via MapKit —
/// another first-party, low-risk Phase 2 integration (docs/architecture.md).
final class GetDirectionsHandler {
    func handle(_ toolCall: ToolCall) {
        guard let destination = toolCall.input["destination"] as? String else { return }

        // TODO (Phase 2): geocode `destination` with CLGeocoder, wrap the result in an
        // MKMapItem, and call `.openInMaps(launchOptions:)` with
        // MKLaunchOptionsDirectionsModeKey set to start turn-by-turn navigation.
        _ = destination
    }
}
