import SwiftUI

@main
struct InfluencerWriterApp: App {
    @StateObject private var store = ScriptStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
