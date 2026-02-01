import SwiftUI
import UniformTypeIdentifiers

struct WriteLibraryView: View {
    @EnvironmentObject private var store: ScriptStore
    @State private var showingEditor: ScriptDocument?
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.scripts) { script in
                        ScriptRowView(script: script, subtitle: "Updated \(formattedDate(script.updatedAt)) • \(script.pageCount) pages")
                            .onTapGesture {
                                showingEditor = script
                            }
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    store.delete(script)
                                }
                            }
                    }
                } header: {
                    Text("My Scripts")
                        .font(.custom("Lato", size: 28).weight(.semibold))
                        .foregroundStyle(Color.purple)
                }

                Section {
                    AdPlaceholderView()
                } header: {
                    Text("Sponsored")
                        .font(.custom("Lato", size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Write")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let script = ScriptDocument(title: "Untitled",
                                                    lines: [ScriptLine(type: .scene, text: "INT. STUDIO - DAY")],
                                                    updatedAt: Date(),
                                                    author: nil)
                        store.save(script: script)
                        showingEditor = script
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isImporting = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("iCloud Backup") {
                        store.syncToICloud()
                    }
                }
            }
            .sheet(item: $showingEditor) { script in
                ScriptEditorView(script: script) { updated in
                    store.save(script: updated)
                }
            }
            .sheet(isPresented: $isImporting) {
                ImportPickerView { url in
                    Task {
                        _ = try? await store.importScript(from: url)
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct AdPlaceholderView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Text("Future Google Ads Banner")
                    .font(.custom("Lato", size: 14))
                    .foregroundStyle(.secondary)
                Text("Place banner between scripts or docked in the library")
                    .font(.custom("Lato", size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ImportPickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let fdxType = UTType(filenameExtension: "fdx") ?? .data
        let docxType = UTType(filenameExtension: "docx") ?? .data
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText, fdxType, docxType, .data])
        controller.allowsMultipleSelection = false
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
