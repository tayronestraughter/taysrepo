import Foundation

struct Script: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var updatedAt: Date
    var isDownload: Bool
    var lines: [ScriptLine]

    init(id: UUID = UUID(), title: String, updatedAt: Date = Date(), isDownload: Bool = false, lines: [ScriptLine]) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.isDownload = isDownload
        self.lines = lines
    }

    var pageEstimate: Int {
        max(1, Int(Double(lines.count) / 55.0) + 1)
    }
}

struct ScriptLine: Identifiable, Codable, Hashable {
    var id: UUID
    var type: LineType
    var text: String
    var style: TextStyle

    init(id: UUID = UUID(), type: LineType, text: String, style: TextStyle = .init()) {
        self.id = id
        self.type = type
        self.text = text
        self.style = style
    }
}

struct TextStyle: Codable, Hashable {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrikethrough: Bool = false
}

enum LineType: String, Codable, CaseIterable, Identifiable {
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

    var defaultNext: LineType {
        switch self {
        case .scene: return .action
        case .action: return .character
        case .character: return .dialogue
        case .parenthesis: return .dialogue
        case .dialogue: return .character
        case .transition: return .scene
        case .shot: return .action
        case .text: return .text
        case .newAct: return .scene
        case .endAct: return .scene
        case .dualDialogue: return .dialogue
        }
    }

    static func guess(from text: String) -> LineType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .action }
        if trimmed.hasPrefix("INT.") || trimmed.hasPrefix("EXT.") || trimmed.hasPrefix("INT/") || trimmed.hasPrefix("I/E") {
            return .scene
        }
        if trimmed.hasPrefix("ACT ") { return .newAct }
        if trimmed.hasPrefix("END ACT") { return .endAct }
        if trimmed.hasPrefix("(") && trimmed.hasSuffix(")") { return .parenthesis }
        if trimmed == trimmed.uppercased(), trimmed.count <= 18 { return .character }
        if trimmed.hasSuffix(":") { return .transition }
        return .action
    }
}
