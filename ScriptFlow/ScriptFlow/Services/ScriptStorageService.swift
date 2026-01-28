import Foundation

struct ScriptStorageService {
    private let fileManager = FileManager.default

    private var scriptsURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        return (documents ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("SCRN", isDirectory: true)
            .appendingPathComponent("scripts.json")
    }

    func loadScripts() throws -> [ScriptDocument] {
        let url = scriptsURL
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([ScriptDocument].self, from: data)
    }

    func saveScripts(_ scripts: [ScriptDocument]) throws {
        let url = scriptsURL
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(scripts)
        try data.write(to: url, options: [.atomic])
    }

    func loadSampleScript() -> [ScriptDocument] {
        guard let url = Bundle.main.url(forResource: "SampleScript", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let scripts = try? JSONDecoder().decode([ScriptDocument].self, from: data) else {
            return []
        }
        return scripts
    }

    func syncToICloud(scripts: [ScriptDocument]) {
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return
        }
        let backupURL = containerURL.appendingPathComponent("Documents/SCRNBackup.json")
        do {
            let data = try JSONEncoder().encode(scripts)
            try data.write(to: backupURL, options: [.atomic])
        } catch {
            print("Failed syncing to iCloud: \(error)")
        }
    }
}
