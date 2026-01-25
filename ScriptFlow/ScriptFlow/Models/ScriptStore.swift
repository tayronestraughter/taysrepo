import Foundation
import SwiftUI

@MainActor
final class ScriptStore: ObservableObject {
    @Published private(set) var scripts: [ScriptDocument] = []
    @Published var showWriteMode: Bool = true

    private let storage: ScriptStorageService

    init(storage: ScriptStorageService = ScriptStorageService()) {
        self.storage = storage
        Task {
            await load()
        }
    }

    func load() async {
        do {
            scripts = try storage.loadScripts()
            if scripts.isEmpty {
                scripts = storage.loadSampleScript()
                try storage.saveScripts(scripts)
            }
        } catch {
            scripts = storage.loadSampleScript()
        }
    }

    func save(script: ScriptDocument) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
        } else {
            scripts.insert(script, at: 0)
        }
        persist()
    }

    func delete(_ script: ScriptDocument) {
        scripts.removeAll { $0.id == script.id }
        persist()
    }

    func persist() {
        do {
            try storage.saveScripts(scripts)
        } catch {
            print("Failed saving scripts: \(error)")
        }
    }

    func importScript(from url: URL) async throws -> ScriptDocument {
        let parser = ImportExportService()
        let script = try parser.importScript(from: url)
        save(script: script)
        return script
    }

    func exportScript(_ script: ScriptDocument, format: ScriptExportFormat) throws -> URL {
        let parser = ImportExportService()
        return try parser.exportScript(script, format: format)
    }

    func syncToICloud() {
        storage.syncToICloud(scripts: scripts)
    }
}
