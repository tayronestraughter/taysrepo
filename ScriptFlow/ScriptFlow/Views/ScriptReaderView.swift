import SwiftUI

struct ScriptReaderView: View {
    @Environment(\.dismiss) private var dismiss
    var script: ScriptDocument

    @State private var textSize: Double = 16
    @State private var isDarkMode = false

    var body: some View {
        VStack(spacing: 0) {
            readerHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(script.lines) { line in
                        Text(styledText(for: line))
                            .font(.custom("CourierPrime", size: textSize))
                            .foregroundStyle(isDarkMode ? Color.white : Color.black)
                            .padding(.leading, line.type.indentation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            Divider()
            readerToolbar
        }
        .background(isDarkMode ? Color.black : Color.white)
    }

    private var readerHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(isDarkMode ? Color.white : Color.black)
            }
            Spacer()
            Text(script.title)
                .font(.custom("Lato", size: 18).weight(.semibold))
                .foregroundStyle(isDarkMode ? Color.white : Color.black)
            Spacer()
            Button {
                // Placeholder for menu
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(isDarkMode ? Color.white : Color.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(isDarkMode ? Color.black : Color.white)
    }

    private var readerToolbar: some View {
        HStack {
            Button {
                textSize = max(12, textSize - 1)
            } label: {
                Label("Text Size", systemImage: "textformat.size.smaller")
            }
            Spacer()
            Button {
                isDarkMode.toggle()
            } label: {
                Label("Light/Dark", systemImage: "circle.lefthalf.filled")
            }
            Spacer()
            Button {
                // Placeholder for jump-to
            } label: {
                Label("Jump To", systemImage: "arrow.turn.down.right")
            }
            Spacer()
            Button {
                // Placeholder for bookmark
            } label: {
                Label("Bookmark", systemImage: "bookmark")
            }
        }
        .font(.custom("Lato", size: 12))
        .foregroundStyle(isDarkMode ? Color.white : Color.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isDarkMode ? Color.black : Color.white)
    }

    private func styledText(for line: ScriptLine) -> AttributedString {
        var text = AttributedString(line.type.uppercase ? line.text.uppercased() : line.text)
        text.font = .custom("CourierPrime", size: textSize)
        if line.style.isBold {
            text.font = (text.font ?? .custom("CourierPrime", size: textSize)).bold()
        }
        if line.style.isItalic {
            text.font = (text.font ?? .custom("CourierPrime", size: textSize)).italic()
        }
        if line.style.isUnderlined {
            text.underlineStyle = .single
        }
        if line.style.isStrikethrough {
            text.strikethroughStyle = .single
        }
        return text
    }
}
