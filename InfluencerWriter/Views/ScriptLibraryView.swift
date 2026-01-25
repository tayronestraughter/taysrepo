import SwiftUI
import UniformTypeIdentifiers

struct ScriptLibraryView: View {
    @EnvironmentObject private var store: ScriptStore
    @State private var isImporterPresented = false
    @State private var importError: String?
    @State private var isBackingUp = false
    @State private var backupMessage: String?

    let mode: LibraryMode

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 24) {
                        scriptSection(title: "My Scripts", scripts: store.myScripts)
                        scriptSection(title: "Downloads", scripts: store.downloads)

                        if mode == .read {
                            AdPlaceholderView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.fdx, .pdf, .docx]) { result in
            switch result {
            case .success(let url):
                do {
                    let script = try ScriptImporter().importScript(from: url)
                    store.upsert(script)
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert("Import Failed", isPresented: Binding(get: { importError != nil }, set: { _ in importError = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "Unknown error")
        }
        .alert("Backup", isPresented: Binding(get: { backupMessage != nil }, set: { _ in backupMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(mode == .read ? "My Scripts" : "Write")
                    .font(.custom("Lato", size: 34))
                    .fontWeight(.semibold)
                    .foregroundStyle(.accentPurple)
                Text(mode == .read ? "Read optimized screenplays" : "Start a new draft or import")
                    .font(.custom("Lato", size: 14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Import Script", systemImage: "square.and.arrow.down") {
                    isImporterPresented = true
                }
                Button("New Script", systemImage: "plus") {
                    let newScript = Script(title: "Untitled", lines: [ScriptLine(type: .scene, text: "INT. SET - DAY")])
                    store.upsert(newScript)
                }
                Button("Backup to iCloud", systemImage: "icloud.and.arrow.up") {
                    Task {
                        isBackingUp = true
                        do {
                            try await store.backupToICloud()
                            backupMessage = "Backup saved to iCloud Drive."
                        } catch {
                            backupMessage = error.localizedDescription
                        }
                        isBackingUp = false
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(.accentPurple)
            }
            .disabled(isBackingUp)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(
            LinearGradient(colors: [Color.accentPurple.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
        )
    }

    private func scriptSection(title: String, scripts: [Script]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !scripts.isEmpty {
                Text(title)
                    .font(.custom("Lato", size: 24))
                    .foregroundStyle(.accentPurple)

                ForEach(scripts) { script in
                    NavigationLink {
                        if mode == .read {
                            ScriptReaderView(script: binding(for: script))
                        } else {
                            ScriptEditorView(script: binding(for: script))
                        }
                    } label: {
                        ScriptRowView(script: script)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func binding(for script: Script) -> Binding<Script> {
        guard let index = store.scripts.firstIndex(where: { $0.id == script.id }) else {
            return .constant(script)
        }
        return $store.scripts[index]
    }
}

enum LibraryMode {
    case read
    case write
}

struct ScriptRowView: View {
    let script: Script

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(script.title)
                    .font(.custom("Lato", size: 20))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            Text("Updated \(script.updatedAt.formatted(date: .abbreviated, time: .omitted)) • \(script.pageEstimate) pages")
                .font(.custom("Lato", size: 12))
                .foregroundStyle(.secondary)
            Divider()
                .overlay(Color.accentPurple.opacity(0.3))
        }
        .padding(.vertical, 8)
    }
}

struct AdPlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.accentPurple.opacity(0.12))
            .frame(height: 96)
            .overlay(
                VStack(spacing: 6) {
                    Text("Future Ads")
                        .font(.custom("Lato", size: 16))
                        .foregroundStyle(.accentPurple)
                    Text("Google Ads banner placeholder")
                        .font(.custom("Lato", size: 12))
                        .foregroundStyle(.secondary)
                }
            )
    }
}

#Preview {
    NavigationStack {
        ScriptLibraryView(mode: .read)
            .environmentObject(ScriptStore())
    }
}
