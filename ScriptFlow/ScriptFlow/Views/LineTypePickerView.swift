import SwiftUI

struct LineTypePickerView: View {
    @Binding var selectedType: ScriptLineType

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ScriptLineType.allCases) { type in
                    Button {
                        selectedType = type
                    } label: {
                        Text(type.displayName.uppercased())
                            .font(.custom("Lato", size: 12).weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedType == type ? Color.purple.opacity(0.2) : Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)
        }
    }
}
