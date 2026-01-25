import SwiftUI

struct ScriptReaderView: View {
    @Binding var script: Script
    @State private var textScale: Double = 1.0
    @State private var isDarkMode = false
    @State private var showMenu = false

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black : Color.white)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                readerHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(script.lines) { line in
                            ReaderLineRow(line: line, scale: textScale)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }

                readerFooter
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showMenu) {
            ReaderMenuSheet(textScale: $textScale, isDarkMode: $isDarkMode)
        }
    }

    private var readerHeader: some View {
        VStack(spacing: 8) {
            Text(script.title)
                .font(.custom("Lato", size: 20))
                .foregroundStyle(isDarkMode ? .white : .accentPurple)
            Divider()
                .background(Color.accentPurple.opacity(0.3))
        }
        .padding(.top, 12)
        .padding(.horizontal, 24)
    }

    private var readerFooter: some View {
        HStack {
            Button {
                showMenu = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            Spacer()

            Button("Text Size") {
                showMenu = true
            }
            .foregroundStyle(.white)

            Spacer()

            Button("Light/Dark") {
                isDarkMode.toggle()
            }
            .foregroundStyle(.white)

            Spacer()

            Button("Jump To") {}
                .foregroundStyle(.white)

            Spacer()

            Button("Bookmark") {}
                .foregroundStyle(.white)
        }
        .font(.custom("Lato", size: 12))
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.panelGradient)
    }
}

struct ReaderLineRow: View {
    let line: ScriptLine
    let scale: Double

    var body: some View {
        let formatting = LineFormatting.forType(line.type)
        Text(line.text)
            .font(.custom("Courier Prime", size: 16 * scale))
            .frame(maxWidth: .infinity, alignment: formatting.alignment)
            .padding(.leading, formatting.leadingPadding)
            .padding(.trailing, formatting.trailingPadding)
    }
}

struct ReaderMenuSheet: View {
    @Binding var textScale: Double
    @Binding var isDarkMode: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Text Size") {
                    Slider(value: $textScale, in: 0.8...1.4, step: 0.1)
                }
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
            }
            .navigationTitle("Reading Settings")
        }
    }
}

#Preview {
    ScriptReaderView(script: .constant(SampleScripts.defaultScripts[0]))
}
