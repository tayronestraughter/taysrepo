import SwiftUI

struct ScriptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ScriptDocument
    @State private var selectedLineType: ScriptLineType = .action
    @State private var selectedLineIndex: Int? = nil
    @State private var undoStack: [[ScriptLine]] = []
    @State private var redoStack: [[ScriptLine]] = []

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
            LineTypePickerView(selectedType: $selectedLineType)
                .padding(.vertical, 8)
            Divider()
            formattingToolbar
        }
        .background(Color.white)
        .onAppear {
            selectedLineType = draft.lines.last?.type ?? .action
        }
        .onChange(of: selectedLineType) { _, newValue in
            guard let index = selectedLineIndex else { return }
            recordUndo()
            draft.lines[index].type = newValue
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
                    .font(.custom("Lato", size: 20).weight(.semibold))
                    .multilineTextAlignment(.center)
                Spacer()
                Button {
                    addLine()
                } label: {
                    Image(systemName: "plus")
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

    private var formattingToolbar: some View {
        HStack(spacing: 20) {
            formatButton(systemName: "bold") { toggleStyle { $0.isBold.toggle() } }
            formatButton(systemName: "italic") { toggleStyle { $0.isItalic.toggle() } }
            formatButton(systemName: "underline") { toggleStyle { $0.isUnderlined.toggle() } }
            formatButton(systemName: "strikethrough") { toggleStyle { $0.isStrikethrough.toggle() } }
            Spacer()
            formatButton(systemName: "arrow.uturn.backward") { undo() }
            formatButton(systemName: "arrow.uturn.forward") { redo() }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(white: 0.95))
    }

    private func formatButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundStyle(Color.purple)
        }
    }

    private func addLine() {
        recordUndo()
        let line = ScriptLine(type: selectedLineType, text: "")
        draft.lines.append(line)
        selectedLineIndex = draft.lines.count - 1
    }

    private func toggleStyle(_ transform: (inout ScriptTextStyle) -> Void) {
        guard let index = selectedLineIndex else { return }
        recordUndo()
        var line = draft.lines[index]
        transform(&line.style)
        draft.lines[index] = line
    }

    private func recordUndo() {
        undoStack.append(draft.lines)
        redoStack.removeAll()
    }

    private func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(draft.lines)
        draft.lines = last
    }

    private func redo() {
        guard let last = redoStack.popLast() else { return }
        undoStack.append(draft.lines)
        draft.lines = last
    }

    private func saveAndDismiss() {
        draft.updatedAt = Date()
        onSave(draft)
        dismiss()
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
            TextField("", text: formattedBinding, axis: .vertical)
                .font(.custom("CourierPrime", size: 16))
                .foregroundStyle(.primary)
                .padding(8)
                .background(isSelected ? Color.purple.opacity(0.1) : Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.leading, line.type.indentation)
                .onTapGesture {
                    onSelect()
                }
        }
    }

    private var formattedBinding: Binding<String> {
        Binding(get: {
            line.type.uppercase ? line.text.uppercased() : line.text
        }, set: { newValue in
            line.text = line.type.uppercase ? newValue.uppercased() : newValue
        })
    }
}
