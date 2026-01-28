import SwiftUI

struct RootTabView: View {
    var body: some View {
        WriteLibraryView()
    @EnvironmentObject private var store: ScriptStore

    var body: some View {
        TabView {
            ReadLibraryView()
                .tabItem {
                    Label("Read", systemImage: "book")
                }
            WriteLibraryView()
                .tabItem {
                    Label("Write", systemImage: "pencil")
                }
        }
        .tint(Color.purple)
    }
}
