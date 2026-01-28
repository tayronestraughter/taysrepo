import Foundation
import PDFKit
import SwiftUI
import UIKit

enum ScriptExportFormat: String, CaseIterable, Identifiable {
    case fdx
    case pdf
    case docx

    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }
}

final class ImportExportService {
    func importScript(from url: URL) throws -> ScriptDocument {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "fdx":
            return try importFDX(from: url)
        case "pdf":
            return try importPDF(from: url)
        case "docx":
            return try importDOCX(from: url)
        default:
            return try importPlainText(from: url)
        }
    }

    func exportScript(_ script: ScriptDocument, format: ScriptExportFormat) throws -> URL {
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(script.title.replacingOccurrences(of: " ", with: "_"))")
            .appendingPathExtension(format.rawValue)
        switch format {
        case .fdx:
            let data = exportFDX(script)
            try data.write(to: exportURL, options: [.atomic])
        case .pdf:
            let data = exportPDF(script)
            try data.write(to: exportURL, options: [.atomic])
        case .docx:
            let data = exportDOCX(script)
            try data.write(to: exportURL, options: [.atomic])
        }
        return exportURL
    }

    private func importFDX(from url: URL) throws -> ScriptDocument {
        let data = try Data(contentsOf: url)
        let parser = XMLParser(data: data)
        let delegate = FDXParserDelegate()
        parser.delegate = delegate
        parser.parse()
        return ScriptDocument(title: url.deletingPathExtension().lastPathComponent,
                              lines: delegate.lines,
                              updatedAt: Date(),
                              author: nil)
    }

    private func importPDF(from url: URL) throws -> ScriptDocument {
        guard let pdf = PDFDocument(url: url) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let text = (0..<pdf.pageCount)
            .compactMap { pdf.page(at: $0)?.string }
            .joined(separator: "\n")
        return ScriptDocument(title: url.deletingPathExtension().lastPathComponent,
                              lines: tokenizePlainText(text),
                              updatedAt: Date(),
                              author: nil)
    }

    private func importDOCX(from url: URL) throws -> ScriptDocument {
        let data = try Data(contentsOf: url)
        if let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.officeOpenXML],
            documentAttributes: nil
        ) {
            return ScriptDocument(title: url.deletingPathExtension().lastPathComponent,
                                  lines: tokenizePlainText(attributed.string),
                                  updatedAt: Date(),
                                  author: nil)
        }
        return try importPlainText(from: url)
    }

    private func importPlainText(from url: URL) throws -> ScriptDocument {
        let text = try String(contentsOf: url)
        return ScriptDocument(title: url.deletingPathExtension().lastPathComponent,
                              lines: tokenizePlainText(text),
                              updatedAt: Date(),
                              author: nil)
    }

    private func tokenizePlainText(_ text: String) -> [ScriptLine] {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { ScriptLine(type: .text, text: String($0)) }
    }

    private func exportFDX(_ script: ScriptDocument) -> Data {
        let header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<FinalDraft>\n<Content>\n"
        let footer = "</Content>\n</FinalDraft>\n"
        let exportLines = titlePageLines(for: script) + script.lines
        let paragraphs = exportLines.map { line in
            let type = line.type.displayName
            let text = escapeXML(line.text)
            return "<Paragraph Type=\"\(type)\"><Text>\(text)</Text></Paragraph>"
        }.joined(separator: "\n")
        let xml = header + paragraphs + "\n" + footer
        return Data(xml.utf8)
    }

    private func exportPDF(_ script: ScriptDocument) -> Data {
        let pageSize = CGSize(width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { context in
            context.beginPage()
            var cursorY: CGFloat = 36
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            let exportLines = titlePageLines(for: script) + script.lines
            for line in exportLines {
                let font = UIFont(name: "CourierPrime", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: paragraphStyle
                ]
                let lineText = line.type.uppercase ? line.text.uppercased() : line.text
                let attributed = NSAttributedString(string: lineText, attributes: attributes)
                let rect = CGRect(x: 36 + CGFloat(line.type.indentation), y: cursorY, width: pageSize.width - 72, height: 20)
                attributed.draw(in: rect)
                cursorY += 20
                if cursorY > pageSize.height - 36 {
                    context.beginPage()
                    cursorY = 36
                }
            }
        }
    }

    private func exportDOCX(_ script: ScriptDocument) -> Data {
        let exportLines = titlePageLines(for: script) + script.lines
        let text = exportLines
            .map { $0.type.uppercase ? $0.text.uppercased() : $0.text }
            .joined(separator: "\n")
        let attributed = NSAttributedString(string: text)
        if let data = try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.officeOpenXML]
        ) {
            return data
        }
        return Data(text.utf8)
    }

    private func escapeXML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func titlePageLines(for script: ScriptDocument) -> [ScriptLine] {
        var lines: [ScriptLine] = []
        lines.append(ScriptLine(type: .text, text: script.title))
        if let author = script.author, !author.isEmpty {
            lines.append(ScriptLine(type: .text, text: "by \(author)"))
        }
        lines.append(ScriptLine(type: .text, text: ""))
        lines.append(ScriptLine(type: .text, text: ""))
        return lines
    }
}

private final class FDXParserDelegate: NSObject, XMLParserDelegate {
    private(set) var lines: [ScriptLine] = []
    private var currentType: ScriptLineType = .text
    private var currentText: String = ""
    private var isInTextElement = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Paragraph" {
            if let type = attributeDict["Type"], let mapped = mapType(type) {
                currentType = mapped
            } else {
                currentType = .text
            }
        }
        if elementName == "Text" {
            isInTextElement = true
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInTextElement else { return }
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Text" {
            isInTextElement = false
            lines.append(ScriptLine(type: currentType, text: currentText.trimmingCharacters(in: .newlines)))
        }
    }

    private func mapType(_ type: String) -> ScriptLineType? {
        switch type.lowercased() {
        case "scene heading": return .scene
        case "action": return .action
        case "character": return .character
        case "parenthetical": return .parenthesis
        case "dialogue": return .dialogue
        case "transition": return .transition
        case "shot": return .shot
        case "text": return .text
        case "new act": return .newAct
        case "end act": return .endAct
        case "dual dialogue": return .dualDialogue
        default: return nil
        }
    }
}
