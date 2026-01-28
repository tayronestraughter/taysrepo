import Foundation

enum ScriptLineType: String, Codable, CaseIterable, Identifiable {
    case scene = "Scene"
    case action = "Action"
    case character = "Character"
    case parenthesis = "Parenthesis"
    case dialogue = "Dialogue"
    case transition = "Transition"
    case shot = "Shot"
    case text = "Text"
    case newAct = "New Act"
    case endAct = "End Act"
    case dualDialogue = "Dual Dialogue"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var indentation: Double {
        switch self {
        case .scene, .action, .transition, .shot, .text, .newAct, .endAct:
            return 0
        case .character:
            return 24
        case .parenthesis:
            return 18
        case .dialogue:
            return 12
        case .dualDialogue:
            return 10
        }
    }

    var uppercase: Bool {
        switch self {
        case .scene, .character, .transition, .shot, .newAct, .endAct:
            return true
        default:
            return false
        }
    }
}

struct ScriptTextStyle: Codable {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderlined: Bool = false
    var isStrikethrough: Bool = false
}

struct ScriptLine: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ScriptLineType
    var text: String
    var style: ScriptTextStyle = ScriptTextStyle()
}

struct ScriptDocument: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var lines: [ScriptLine]
    var updatedAt: Date
    var author: String?

    var pageCount: Int {
        max(1, Int(ceil(Double(lines.count) / 35.0)))
    }
}

struct ScriptLibrarySection: Identifiable {
    var id: UUID = UUID()
    var title: String
    var scripts: [ScriptDocument]
}
