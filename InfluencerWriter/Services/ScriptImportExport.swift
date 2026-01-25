import Foundation
import PDFKit
import UniformTypeIdentifiers
import UIKit

enum ScriptImportError: Error {
    case unsupportedFormat
    case failedToParse
}

struct ScriptImporter {
    func importScript(from url: URL) throws -> Script {
        let shouldStop = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStop { url.stopAccessingSecurityScopedResource() }
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "fdx":
            return try FDXParser().parse(url: url)
        case "docx":
            return try DocxParser().parse(url: url)
        case "pdf":
            return try PDFScriptParser().parse(url: url)
        default:
            throw ScriptImportError.unsupportedFormat
        }
    }
}

struct ScriptExporter {
    func export(script: Script, as fileType: ExportType) throws -> URL {
        let temp = FileManager.default.temporaryDirectory
        switch fileType {
        case .fdx:
            let url = temp.appendingPathComponent("\(script.title).fdx")
            let data = try FDXExporter().makeFDX(script: script)
            try data.write(to: url, options: [.atomic])
            return url
        case .pdf:
            let url = temp.appendingPathComponent("\(script.title).pdf")
            try PDFExporter().makePDF(script: script, to: url)
            return url
        case .docx:
            let url = temp.appendingPathComponent("\(script.title).docx")
            try DocxExporter().makeDOCX(script: script, to: url)
            return url
        }
    }
}

enum ExportType: String, CaseIterable, Identifiable {
    case fdx = "Final Draft (.fdx)"
    case docx = "Word (.docx)"
    case pdf = "PDF (.pdf)"

    var id: String { rawValue }
}

final class FDXParser: NSObject, XMLParserDelegate {
    private var currentType: LineType = .action
    private var currentText = ""
    private var lines: [ScriptLine] = []
    private var inText = false

    func parse(url: URL) throws -> Script {
        guard let parser = XMLParser(contentsOf: url) else {
            throw ScriptImportError.failedToParse
        }
        parser.delegate = self
        parser.parse()
        return Script(title: url.deletingPathExtension().lastPathComponent, isDownload: true, lines: lines)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Paragraph", let type = attributeDict["Type"] {
            currentType = mapFDXType(type)
            currentText = ""
        }
        if elementName == "Text" {
            inText = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inText else { return }
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Text" {
            inText = false
        }
        if elementName == "Paragraph" {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lines.append(ScriptLine(type: currentType, text: trimmed))
            }
        }
    }

    private func mapFDXType(_ type: String) -> LineType {
        switch type.lowercased() {
        case "scene heading": return .scene
        case "action": return .action
        case "character": return .character
        case "parenthetical": return .parenthesis
        case "dialogue": return .dialogue
        case "transition": return .transition
        case "shot": return .shot
        case "text": return .text
        case "act": return .newAct
        case "end of act": return .endAct
        case "dual dialogue": return .dualDialogue
        default: return .action
        }
    }
}

final class DocxParser: NSObject, XMLParserDelegate {
    private var lines: [ScriptLine] = []
    private var currentText = ""
    private var inText = false

    func parse(url: URL) throws -> Script {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw ScriptImportError.failedToParse
        }
        guard let entry = archive["word/document.xml"] else {
            throw ScriptImportError.failedToParse
        }
        var xmlData = Data()
        _ = try archive.extract(entry) { data in
            xmlData.append(data)
        }
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
        return Script(title: url.deletingPathExtension().lastPathComponent, isDownload: true, lines: lines)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "w:p" {
            currentText = ""
        }
        if elementName == "w:t" {
            inText = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inText else { return }
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "w:t" {
            inText = false
        }
        if elementName == "w:p" {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            lines.append(ScriptLine(type: LineType.guess(from: trimmed), text: trimmed))
        }
    }
}

struct PDFScriptParser {
    func parse(url: URL) throws -> Script {
        guard let document = PDFDocument(url: url), let text = document.string else {
            throw ScriptImportError.failedToParse
        }
        let rawLines = text
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let lines = rawLines.map { ScriptLine(type: LineType.guess(from: $0), text: $0) }
        return Script(title: url.deletingPathExtension().lastPathComponent, isDownload: true, lines: lines)
    }
}

struct FDXExporter {
    func makeFDX(script: Script) throws -> Data {
        let content = script.lines.map { line -> String in
            let type = mapLineType(line.type)
            return "    <Paragraph Type=\"\(type)\"><Text>\(escape(line.text))</Text></Paragraph>"
        }.joined(separator: "\n")

        let xml = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <FinalDraft DocumentType=\"Script\" Template=\"Script\" Version=\"1\">
          <Content>
        \(content)
          </Content>
        </FinalDraft>
        """
        guard let data = xml.data(using: .utf8) else { throw ScriptImportError.failedToParse }
        return data
    }

    private func mapLineType(_ type: LineType) -> String {
        switch type {
        case .scene: return "Scene Heading"
        case .action: return "Action"
        case .character: return "Character"
        case .parenthesis: return "Parenthetical"
        case .dialogue: return "Dialogue"
        case .transition: return "Transition"
        case .shot: return "Shot"
        case .text: return "Text"
        case .newAct: return "Act"
        case .endAct: return "End of Act"
        case .dualDialogue: return "Dual Dialogue"
        }
    }

    private func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

struct PDFExporter {
    func makePDF(script: Script, to url: URL) throws {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 72
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier Prime", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .paragraphStyle: paragraphStyle
            ]
            let text = script.lines.map { $0.text }.joined(separator: "\n")
            text.draw(in: CGRect(x: 72, y: y, width: 468, height: pageRect.height - 144), withAttributes: attributes)
        }
        try data.write(to: url, options: [.atomic])
    }
}

struct DocxExporter {
    func makeDOCX(script: Script, to url: URL) throws {
        let contentTypes = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">
          <Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>
          <Default Extension=\"xml\" ContentType=\"application/xml\"/>
          <Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>
        </Types>
        """
        let rels = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">
          <Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>
        </Relationships>
        """
        let documentRels = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\"></Relationships>
        """
        let paragraphs = script.lines.map { line in
            "<w:p><w:r><w:t>\(escape(line.text))</w:t></w:r></w:p>"
        }.joined()
        let document = """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">
          <w:body>
            \(paragraphs)
          </w:body>
        </w:document>
        """

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        guard let archive = Archive(url: url, accessMode: .create) else {
            throw ScriptImportError.failedToParse
        }
        try addEntry(path: "[Content_Types].xml", content: contentTypes, to: archive)
        try addEntry(path: "_rels/.rels", content: rels, to: archive)
        try addEntry(path: "word/document.xml", content: document, to: archive)
        try addEntry(path: "word/_rels/document.xml.rels", content: documentRels, to: archive)
    }

    private func addEntry(path: String, content: String, to archive: Archive) throws {
        guard let data = content.data(using: .utf8) else { return }
        try archive.addEntry(with: path, type: .file, uncompressedSize: UInt32(data.count), compressionMethod: .deflate, provider: { position, size in
            let start = Int(position)
            let end = min(start + Int(size), data.count)
            return data.subdata(in: start..<end)
        })
    }

    private func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

extension UTType {
    static let fdx = UTType(exportedAs: "com.finaldraft.fdx")
}
