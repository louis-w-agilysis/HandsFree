import CoreLocation
import MapKit

/// Implements the `get_directions` tool (backend/src/tools/schema.ts) via MapKit — no
/// location permission needed for forward-geocoding a destination string or handing
/// off to Maps. Returns a result string so the user always hears whether it actually
/// worked — see docs/risk-assessment.md.
final class GetDirectionsHandler {
    func handle(_ toolCall: ToolCall) async -> String {
        guard let destination = toolCall.input["destination"] as? String, !destination.isEmpty else {
            return "Couldn't get directions — no destination was given."
        }

        let geocoder = CLGeocoder()
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.geocodeAddressString(destination)
        } catch {
            return "Couldn't look up \(destination): \(error.localizedDescription)"
        }

        guard let placemark = placemarks.first else {
            return "Couldn't find a location for \(destination)."
        }

        let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
        mapItem.name = destination
        await MainActor.run {
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
        return "Starting directions to \(destination)."
    }
}
