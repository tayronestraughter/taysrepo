import SwiftUI

struct ScriptEditorView: View {
    @Binding var script: Script
    @State private var selectedLineType: LineType = .action
    @State private var showMenu = false
    @State private var exportURL: URL?
    @State private var exportType: ExportType = .fdx
    @State private var exportError: String?
    @State private var activeLineID: ScriptLine.ID?
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                editorHeader

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach($script.lines) { $line in
                                EditorLineRow(line: $line, isActive: line.id == activeLineID)
                                    .onTapGesture {
                                        activeLineID = line.id
                                    }
                                    .id(line.id)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                }

                TextStyleBar(onBold: { toggleStyle { $0.isBold.toggle() } },
                             onItalic: { toggleStyle { $0.isItalic.toggle() } },
                             onUnderline: { toggleStyle { $0.isUnderline.toggle() } },
                             onStrikethrough: { toggleStyle { $0.isStrikethrough.toggle() } },
                             onUndo: { undoManager?.undo() },
                             onRedo: { undoManager?.redo() })

                LineTypeBar(selectedLineType: $selectedLineType) { type in
                    addLine(type: type)
                }
            }
        }
        .sheet(isPresented: $showMenu) {
            EditorMenuSheet(script: $script, exportType: $exportType, onExport: export)
        }
        .onChange(of: script.lines) { _ in
            script.updatedAt = Date()
        }
        .onChange(of: script.title) { _ in
            script.updatedAt = Date()
        }
        .sheet(item: $exportURL) { url in
            ShareLink(item: url)
                .presentationDetents([.medium])
        }
        .alert("Export Failed", isPresented: Binding(get: { exportError != nil }, set: { _ in exportError = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private var editorHeader: some View {
        HStack {
            Button {
                showMenu = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(script.title)
                    .font(.custom("Lato", size: 20))
                    .foregroundStyle(.white)
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 120, height: 1)
            }

            Spacer()

            Button {
                addLine(type: selectedLineType)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color.panelGradient)
    }

    private func addLine(type: LineType) {
        let newLine = ScriptLine(type: type, text: "")
        script.lines.append(newLine)
        activeLineID = newLine.id
        selectedLineType = type.defaultNext
    }

    private func toggleStyle(_ update: (inout TextStyle) -> Void) {
        guard let activeLineID,
              let index = script.lines.firstIndex(where: { $0.id == activeLineID }) else { return }
        update(&script.lines[index].style)
    }

    private func export() {
        do {
            let url = try ScriptExporter().export(script: script, as: exportType)
            exportURL = url
        } catch {
            exportError = error.localizedDescription
        }
    }
}

struct EditorLineRow: View {
    @Binding var line: ScriptLine
    var isActive: Bool

    var body: some View {
        let formatting = LineFormatting.forType(line.type)
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(line.type.displayName.uppercased())
                    .font(.custom("Lato", size: 10))
                    .foregroundStyle(.accentPurple)
                    .frame(width: 90, alignment: .leading)

                TextField("", text: $line.text, axis: .vertical)
                    .font(.custom("Courier Prime", size: 16))
                    .fontWeight(line.style.isBold ? .bold : .regular)
                    .italic(line.style.isItalic)
                    .underline(line.style.isUnderline)
                    .strikethrough(line.style.isStrikethrough)
                    .lineSpacing(4)
                    .textInputAutocapitalization(.sentences)
                    .frame(maxWidth: .infinity, alignment: formatting.alignment)
                    .padding(.leading, formatting.leadingPadding)
                    .padding(.trailing, formatting.trailingPadding)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.accentPurple.opacity(0.08) : Color.clear)
            )

            Divider()
                .overlay(Color.accentPurple.opacity(0.15))
        }
    }
}

struct LineTypeBar: View {
    @Binding var selectedLineType: LineType
    var onAddLine: (LineType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LineType.allCases) { type in
                    Button {
                        selectedLineType = type
                        onAddLine(type)
                    } label: {
                        Text(type.displayName.uppercased())
                            .font(.custom("Lato", size: 12))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(type == selectedLineType ? Color.accentPurple.opacity(0.8) : Color.gray.opacity(0.2))
                            )
                            .foregroundStyle(type == selectedLineType ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.gray.opacity(0.1))
    }
}

struct TextStyleBar: View {
    var onBold: () -> Void
    var onItalic: () -> Void
    var onUnderline: () -> Void
    var onStrikethrough: () -> Void
    var onUndo: () -> Void
    var onRedo: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            styleButton(title: "B", action: onBold)
            styleButton(title: "I", action: onItalic)
            styleButton(title: "U", action: onUnderline)
            styleButton(title: "S", action: onStrikethrough)
            Spacer()
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
            }
            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
            }
        }
        .font(.custom("Lato", size: 14))
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.08))
    }

    private func styleButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Lato", size: 14))
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.accentPurple.opacity(0.4), lineWidth: 1)
                )
        }
    }
}

struct EditorMenuSheet: View {
    @Binding var script: Script
    @Binding var exportType: ExportType
    var onExport: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("File") {
                    HStack {
                        Text("Title")
                        Spacer()
                        TextField("Title", text: $script.title)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Edit") {
                    Text("Undo")
                    Text("Redo")
                }

                Section("Format") {
                    ForEach(LineType.allCases) { type in
                        Text(type.displayName)
                    }
                }

                Section("Export") {
                    Picker("Format", selection: $exportType) {
                        ForEach(ExportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Button("Export Now") {
                        onExport()
                    }
                }
            }
            .navigationTitle("Menu")
        }
    }
}

#Preview {
    ScriptEditorView(script: .constant(SampleScripts.defaultScripts[0]))
}
