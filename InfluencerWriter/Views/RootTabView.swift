import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ScriptLibraryView(mode: .read)
            }
            .tabItem {
                Label("Read", systemImage: "book")
            }

            NavigationStack {
                ScriptLibraryView(mode: .write)
            }
            .tabItem {
                Label("Write", systemImage: "pencil")
            }
        }
        .tint(.accentPurple)
    }
}

#Preview {
    RootTabView()
        .environmentObject(ScriptStore())
}
