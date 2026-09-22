import SwiftUI

@main
struct HandsFreeApp: App {
    @StateObject private var conversation = ConversationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(conversation)
        }
    }
}
