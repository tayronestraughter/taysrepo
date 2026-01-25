import SwiftUI

struct LineFormatting {
    let alignment: Alignment
    let leadingPadding: CGFloat
    let trailingPadding: CGFloat

    static func forType(_ type: LineType) -> LineFormatting {
        switch type {
        case .scene, .transition, .shot, .newAct, .endAct:
            return LineFormatting(alignment: .leading, leadingPadding: 0, trailingPadding: 0)
        case .character:
            return LineFormatting(alignment: .center, leadingPadding: 60, trailingPadding: 60)
        case .parenthesis:
            return LineFormatting(alignment: .center, leadingPadding: 80, trailingPadding: 80)
        case .dialogue, .dualDialogue:
            return LineFormatting(alignment: .leading, leadingPadding: 40, trailingPadding: 40)
        case .action, .text:
            return LineFormatting(alignment: .leading, leadingPadding: 0, trailingPadding: 0)
        }
    }
}
