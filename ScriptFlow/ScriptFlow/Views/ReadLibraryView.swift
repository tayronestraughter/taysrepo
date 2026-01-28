import SwiftUI

struct ReadLibraryView: View {
    @EnvironmentObject private var store: ScriptStore
    @State private var selectedScript: ScriptDocument?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.scripts) { script in
                        ScriptRowView(script: script, subtitle: "By \(script.author ?? "Author") • \(script.pageCount) pages")
                            .onTapGesture {
                                selectedScript = script
                            }
                    }
                } header: {
                    Text("My Scripts")
                        .font(.custom("Lato", size: 28).weight(.semibold))
                        .foregroundStyle(Color.purple)
                }

                Section {
                    Text("No downloads yet. Imported scripts appear here.")
                        .font(.custom("Lato", size: 14))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } header: {
                    Text("Downloads")
                        .font(.custom("Lato", size: 20))
                        .foregroundStyle(Color.purple)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Read")
            .sheet(item: $selectedScript) { script in
                ScriptReaderView(script: script)
            }
        }
    }
}
