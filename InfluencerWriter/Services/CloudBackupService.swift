import Foundation

struct CloudBackupService {
    func backup(dataURL: URL) throws {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw BackupError.iCloudUnavailable
        }
        let backupFolder = containerURL.appendingPathComponent("Documents/ScriptWave Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        let destination = backupFolder.appendingPathComponent("scripts-backup.json")
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: dataURL, to: destination)
    }
}

enum BackupError: LocalizedError {
    case iCloudUnavailable

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud Drive is not available on this device."
        }
    }
}
