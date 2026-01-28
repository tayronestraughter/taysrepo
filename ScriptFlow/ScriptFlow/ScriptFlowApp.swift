import SwiftUI

@main
struct SCRNApp: App {
    @StateObject private var store = ScriptStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
