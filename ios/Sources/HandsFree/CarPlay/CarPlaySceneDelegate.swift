import CarPlay

/// The in-car surface — see docs/architecture.md. Real device testing needs Apple's
/// approval of the "voice-based conversational app" CarPlay entitlement (docs/roadmap.md
/// Phase 6); this is scaffolded ahead of that so the shape exists, not because it's
/// usable yet.
final class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        // TODO (Phase 6): present a voice-first template once the CarPlay entitlement
        // is approved. Apple's voice-conversational-app category requires launching
        // directly into voice interaction rather than a menu.
    }
}
