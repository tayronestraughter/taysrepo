import SwiftUI
import UniformTypeIdentifiers

struct ScriptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ScriptDocument
    @State private var selectedLineType: ScriptLineType = .action
    @State private var selectedLineIndex: Int? = nil
    @State private var showingFileSheet = false
    @State private var showingExportOptions = false
    @State private var exportURL: URL?
    @State private var showingExporter = false
    @State private var selectedExportFormat: ScriptExportFormat = .fdx

    var onSave: (ScriptDocument) -> Void

    init(script: ScriptDocument, onSave: @escaping (ScriptDocument) -> Void) {
        _draft = State(initialValue: script)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(draft.lines.indices, id: \.self) { index in
                        ScriptLineEditorRow(
                            line: $draft.lines[index],
                            isSelected: selectedLineIndex == index
                        ) {
                            selectedLineIndex = index
                            selectedLineType = draft.lines[index].type
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            Divider()
            currentLineIndicator
            LineTypePickerView(selectedType: $selectedLineType)
                .padding(.vertical, 8)
        }
        .background(Color.white)
        .onAppear {
            selectedLineType = draft.lines.last?.type ?? .action
        }
        .onChange(of: selectedLineType) { _, newValue in
            guard let index = selectedLineIndex else { return }
            draft.lines[index].type = newValue
        }
        .confirmationDialog("Export", isPresented: $showingExportOptions, titleVisibility: .visible) {
            ForEach(ScriptExportFormat.allCases) { format in
                Button(format.displayName) {
                    selectedExportFormat = format
                    prepareExport()
                }
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: ExportDocument(url: exportURL),
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { _ in }
        .sheet(isPresented: $showingFileSheet) {
            FileDetailsSheet(title: $draft.title, author: Binding(
                get: { draft.author ?? "" },
                set: { draft.author = $0.isEmpty ? nil : $0 }
            ))
        }
    }

    private var editorHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    saveAndDismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                Spacer()
                TextField("Title", text: $draft.title)
                    .font(.custom("Lato", size: 20).weight(.bold))
                    .multilineTextAlignment(.center)
                Spacer()
                Menu {
                    Button("File") {
                        showingFileSheet = true
                    }
                    Button("Export") {
                        showingExportOptions = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)

            Rectangle()
                .fill(Color.purple.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.top, 12)
    }

    private var currentLineIndicator: some View {
        HStack {
            Text("Current line type: \(selectedLineType.displayName)")
                .font(.custom("Lato", size: 12).weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                addLine()
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(Color.purple)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func addLine() {
        let line = ScriptLine(type: selectedLineType, text: "")
        draft.lines.append(line)
        selectedLineIndex = draft.lines.count - 1
        selectedLineType = nextLineType(after: line.type)
    }

    private func nextLineType(after current: ScriptLineType) -> ScriptLineType {
        switch current {
        case .scene:
            return .action
        case .action:
            return .character
        case .character:
            return .dialogue
        default:
            return .action
        }
    }

    private func saveAndDismiss() {
        draft.updatedAt = Date()
        onSave(draft)
        dismiss()
    }

    private func prepareExport() {
        let service = ImportExportService()
        exportURL = try? service.exportScript(draft, format: selectedExportFormat)
        showingExporter = exportURL != nil
    }

    private var exportContentType: UTType {
        switch selectedExportFormat {
        case .fdx:
            return UTType(filenameExtension: "fdx") ?? .data
        case .pdf:
            return .pdf
        case .docx:
            return UTType(filenameExtension: "docx") ?? .data
        }
    }

    private var exportFilename: String {
        let base = draft.title.isEmpty ? "Untitled" : draft.title
        return "\(base).\(selectedExportFormat.rawValue)"
    }
}

private struct ScriptLineEditorRow: View {
    @Binding var line: ScriptLine
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(line.type.displayName.uppercased())
                .font(.custom("Lato", size: 10).weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            ScriptLineTextView(text: $line.text, lineType: line.type, isSelected: isSelected)
                .frame(minHeight: 36)
                .padding(8)
                .background(isSelected ? Color.purple.opacity(0.1) : Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.leading, line.type.indentation)
                .onTapGesture {
                    onSelect()
                }
        }
    }
}

private struct ScriptLineTextView: UIViewRepresentable {
    @Binding var text: String
    var lineType: ScriptLineType
    var isSelected: Bool

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.font = UIFont(name: "CourierPrime", size: 16) ?? UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        view.backgroundColor = .clear
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.isScrollEnabled = false
        view.delegate = context.coordinator
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let adjustedText = lineType.uppercase ? text.uppercased() : text
        if uiView.text != adjustedText {
            uiView.text = adjustedText
            if text != adjustedText {
                text = adjustedText
            }
        }
        if lineType == .parenthesis, context.coordinator.lastLineType != .parenthesis {
            if text.isEmpty {
                uiView.text = "()"
                text = "()"
                DispatchQueue.main.async {
                    uiView.selectedRange = NSRange(location: 1, length: 0)
                }
            }
        }
        context.coordinator.lastLineType = lineType
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        var lastLineType: ScriptLineType = .text

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}

private struct FileDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var title: String
    @Binding var author: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Script") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                }
            }
            .navigationTitle("File")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    var url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        return FileWrapper(regularFileWithContents: data)
    }
}
