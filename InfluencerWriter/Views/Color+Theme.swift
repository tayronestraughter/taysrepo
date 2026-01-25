import SwiftUI

extension Color {
    static let accentPurple = Color(red: 0.47, green: 0.32, blue: 0.85)
    static let accentBlue = Color(red: 0.33, green: 0.45, blue: 0.86)
    static let panelGradient = LinearGradient(
        colors: [Color.accentBlue.opacity(0.9), Color.accentPurple.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
