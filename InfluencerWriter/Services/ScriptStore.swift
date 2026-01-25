import Foundation
import Combine

final class ScriptStore: ObservableObject {
    @Published private(set) var scripts: [Script] = []

    private let fileURL: URL
    private let backupService = CloudBackupService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent("scripts.json")
        load()
        $scripts
            .dropFirst()
            .debounce(for: .seconds(0.4), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    var myScripts: [Script] {
        scripts.filter { !$0.isDownload }
    }

    var downloads: [Script] {
        scripts.filter { $0.isDownload }
    }

    func script(id: Script.ID) -> Script? {
        scripts.first { $0.id == id }
    }

    func upsert(_ script: Script) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
        } else {
            scripts.append(script)
        }
    }

    func delete(_ script: Script) {
        scripts.removeAll { $0.id == script.id }
    }

    func backupToICloud() async throws {
        try backupService.backup(dataURL: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            scripts = SampleScripts.defaultScripts
            return
        }
        do {
            scripts = try JSONDecoder().decode([Script].self, from: data)
        } catch {
            scripts = SampleScripts.defaultScripts
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(scripts)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save scripts: \(error)")
        }
    }
}
