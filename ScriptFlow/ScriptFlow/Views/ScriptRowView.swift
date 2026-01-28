import SwiftUI

struct ScriptRowView: View {
    var script: ScriptDocument
    var subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(script.title)
                    .font(.custom("Lato", size: 20).weight(.medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.custom("Lato", size: 14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
