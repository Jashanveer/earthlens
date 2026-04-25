import Foundation

enum AppPaths {
    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("EarthLens", isDirectory: true)
    }

    static var legacySupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("TerraFrame", isDirectory: true)
    }

    static var imagesDirectory: URL {
        supportDirectory.appendingPathComponent("Images", isDirectory: true)
    }

    static var stateFile: URL {
        supportDirectory.appendingPathComponent("state.json")
    }

    static var catalogCacheFile: URL {
        supportDirectory.appendingPathComponent("catalog-cache.json")
    }

    static var logFile: URL {
        supportDirectory.appendingPathComponent("earthlens.log")
    }

    static func ensureDirectories() throws {
        try migrateLegacySupportDirectoryIfNeeded()
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    private static func migrateLegacySupportDirectoryIfNeeded() throws {
        let fileManager = FileManager.default
        guard
            fileManager.fileExists(atPath: legacySupportDirectory.path),
            !fileManager.fileExists(atPath: supportDirectory.path)
        else {
            return
        }

        try fileManager.moveItem(at: legacySupportDirectory, to: supportDirectory)
    }
}
