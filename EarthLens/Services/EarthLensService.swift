import AppKit
import Foundation

actor EarthLensService {
    private let fileManager = FileManager.default
    private let catalogURL = URL(string: "https://raw.githubusercontent.com/limhenry/earthview/master/earthview.json")!
    private let imageBaseURL = URL(string: "https://www.gstatic.com/prettyearth/assets/full/")!
    private let catalogMaxAge: TimeInterval = 60 * 60 * 24 * 7
    private let maxLogFileBytes: UInt64 = 256 * 1024

    func loadSnapshot(forceRefresh: Bool = false) async throws -> AppSnapshot {
        try AppPaths.ensureDirectories()

        var state = try loadState()
        normalize(&state)
        let catalog = try await loadCatalog(forceRefresh: forceRefresh)

        try saveState(state)
        return makeSnapshot(from: state, catalog: catalog)
    }

    func setNextWallpaper() async throws -> AppSnapshot {
        try AppPaths.ensureDirectories()

        var state = try loadState()
        normalize(&state)
        let catalog = try await loadCatalog(forceRefresh: false)
        try await advanceToNextWallpaper(state: &state, catalog: catalog)

        try saveState(state)
        return makeSnapshot(from: state, catalog: catalog)
    }

    func setPreviousWallpaper() async throws -> AppSnapshot {
        try AppPaths.ensureDirectories()

        var state = try loadState()
        normalize(&state)
        let catalog = try await loadCatalog(forceRefresh: false)

        guard let cursor = state.historyCursor, cursor > 0 else {
            throw EarthLensError.noPreviousWallpaper
        }

        let previousID = state.history[cursor - 1]
        let imageURL = try await downloadImage(id: previousID)

        try await setWallpaper(at: imageURL)

        state.historyCursor = cursor - 1
        state.currentID = previousID
        state.currentImageFilename = imageURL.lastPathComponent
        state.lastUpdatedAt = Date()

        try saveState(state)
        return makeSnapshot(from: state, catalog: catalog)
    }

    func updateRotation(enabled: Bool, interval: RotationInterval, advanceImmediately: Bool = false) async throws -> AppSnapshot {
        try AppPaths.ensureDirectories()

        var state = try loadState()
        normalize(&state)
        state.rotationInterval = interval

        if enabled {
            if advanceImmediately {
                let catalog = try await loadCatalog(forceRefresh: false)
                try await advanceToNextWallpaper(state: &state, catalog: catalog)
            }

            state.rotationEnabled = true
            state.setupCompleted = true
            try saveState(state)

            do {
                try LoginItemService.register()
            } catch {
                appendLog("Login item registration failed: \(error.localizedDescription)")
            }
        } else {
            do {
                try await LoginItemService.unregister()
            } catch {
                appendLog("Login item unregistration failed: \(error.localizedDescription)")
            }
            state.rotationEnabled = false
            try saveState(state)
        }

        return try await loadSnapshot(forceRefresh: false)
    }

    func configureFirstRun(interval: RotationInterval) async throws -> AppSnapshot {
        try AppPaths.ensureDirectories()

        var state = try loadState()
        normalize(&state)
        let catalog = try await loadCatalog(forceRefresh: false)

        if state.currentID == nil {
            try await advanceToNextWallpaper(state: &state, catalog: catalog)
        }

        state.rotationEnabled = true
        state.rotationInterval = interval
        state.setupCompleted = true
        try saveState(state)

        do {
            try LoginItemService.register()
        } catch {
            appendLog("Login item registration failed: \(error.localizedDescription)")
        }

        return try await loadSnapshot(forceRefresh: false)
    }

    func markSetupCompleted() async throws -> AppSnapshot {
        try AppPaths.ensureDirectories()

        var state = try loadState()
        normalize(&state)
        state.setupCompleted = true
        try saveState(state)
        return try await loadSnapshot(forceRefresh: false)
    }

    func appendLog(_ message: String) {
        let line = "[\(Date().formatted(date: .abbreviated, time: .standard))] \(message)\n"
        let data = Data(line.utf8)

        guard fileManager.fileExists(atPath: AppPaths.logFile.path) else {
            try? data.write(to: AppPaths.logFile, options: .atomic)
            return
        }

        trimLogIfNeeded()

        if let handle = try? FileHandle(forWritingTo: AppPaths.logFile) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        }
    }

    private func trimLogIfNeeded() {
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: AppPaths.logFile.path),
            let size = attributes[.size] as? UInt64,
            size > maxLogFileBytes,
            let existing = try? Data(contentsOf: AppPaths.logFile)
        else {
            return
        }

        let keepBytes = Int(maxLogFileBytes / 2)
        let suffix = existing.suffix(keepBytes)
        try? Data(suffix).write(to: AppPaths.logFile, options: .atomic)
    }

    private func makeSnapshot(from state: PersistedState, catalog: CatalogCache) -> AppSnapshot {
        let uniqueHistoryCount = Set(state.history).count
        let historyCursor = state.historyCursor ?? (state.history.isEmpty ? nil : state.history.count - 1)
        let currentEntry = catalog.entries.first { $0.id == state.currentID }
        let currentImageURL: URL? = {
            guard let currentImageFilename = state.currentImageFilename else { return nil }
            let url = AppPaths.imagesDirectory.appendingPathComponent(currentImageFilename)
            return fileManager.fileExists(atPath: url.path) ? url : nil
        }()

        return AppSnapshot(
            totalCount: catalog.entries.count,
            seenCount: uniqueHistoryCount,
            remainingCount: max(catalog.entries.count - uniqueHistoryCount, 0),
            currentID: state.currentID,
            currentImageURL: currentImageURL,
            catalogUpdatedAt: catalog.fetchedAt,
            rotationEnabled: state.rotationEnabled,
            rotationInterval: state.rotationInterval,
            canGoPrevious: (historyCursor ?? 0) > 0,
            canGoForward: historyCursor.map { $0 < state.history.count - 1 } ?? false,
            displayTitle: currentEntry?.title ?? (state.currentID == nil ? "Ready for a first wallpaper" : "Earth View"),
            displaySubtitle: currentEntry?.subtitle ?? (state.currentID == nil ? "Load the first scene to start the gallery." : nil),
            setupCompleted: state.setupCompleted
        )
    }

    private func loadCatalog(forceRefresh: Bool) async throws -> CatalogCache {
        if
            !forceRefresh,
            let cached = try? readCatalogCache(),
            !cached.entries.isEmpty,
            cached.entries.contains(where: { $0.title != nil || $0.subtitle != nil }),
            Date().timeIntervalSince(cached.fetchedAt) < catalogMaxAge
        {
            return cached
        }

        do {
            let fetched = try await fetchRemoteCatalog()
            try saveCatalogCache(fetched)
            return fetched
        } catch {
            if let fallback = try? readCatalogCache(), !fallback.entries.isEmpty {
                return fallback
            }

            if let earthLensError = error as? EarthLensError {
                throw earthLensError
            }

            throw EarthLensError.downloadFailed(error.localizedDescription)
        }
    }

    private func fetchRemoteCatalog() async throws -> CatalogCache {
        let (data, response) = try await URLSession.shared.data(from: catalogURL)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw EarthLensError.downloadFailed("Catalog request failed.")
        }

        let entries = extractEntries(from: data)
        guard !entries.isEmpty else {
            throw EarthLensError.emptyCatalog
        }

        return CatalogCache(entries: entries, fetchedAt: Date())
    }

    private func extractEntries(from data: Data) -> [EarthViewEntry] {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        let rawItems: [[String: Any]]
        if let array = object as? [[String: Any]] {
            rawItems = array
        } else if let dictionary = object as? [String: Any], let array = dictionary["results"] as? [[String: Any]] {
            rawItems = array
        } else {
            return []
        }

        let entries = rawItems.compactMap(parseEntry(from:))
        let deduped = Dictionary(grouping: entries, by: \.id).compactMap { _, values in
            values.first
        }

        return deduped.sorted { $0.id < $1.id }
    }

    private func parseEntry(from item: [String: Any]) -> EarthViewEntry? {
        guard let id = parseID(from: item["id"]) ?? parseImageID(from: item["image"]) else {
            return nil
        }

        let explicitTitle = firstNonEmptyString(in: item, keys: ["title", "name", "description", "caption", "summary"])
        let locality = firstNonEmptyString(in: item, keys: ["locality", "city", "town", "village", "place"])
        let region = firstNonEmptyString(in: item, keys: ["region", "state", "province", "county", "administrative_area"])
        let country = firstNonEmptyString(in: item, keys: ["country", "country_name"])
        let geocode = (item["geocode"] as? [Any])?.compactMap { value -> String? in
            guard let string = value as? String else { return nil }
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } ?? []

        let locationLine = uniqueStrings([locality, region, country] + geocode).joined(separator: ", ")

        if let explicitTitle {
            let subtitle = normalizedLine(locationLine, excluding: explicitTitle)
            return EarthViewEntry(id: id, title: explicitTitle, subtitle: subtitle)
        }

        if !locationLine.isEmpty {
            return EarthViewEntry(id: id, title: locationLine, subtitle: nil)
        }

        return EarthViewEntry(id: id, title: nil, subtitle: nil)
    }

    private func parseID(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        if let string = value as? String {
            return Int(string)
        }

        return nil
    }

    private func parseImageID(from value: Any?) -> Int? {
        guard let string = value as? String else {
            return nil
        }

        let pattern = #"/([0-9]+)\.jpg"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..<string.endIndex, in: string)),
            match.numberOfRanges > 1,
            let idRange = Range(match.range(at: 1), in: string)
        else {
            return nil
        }

        return Int(string[idRange])
    }

    private func firstNonEmptyString(in item: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let string = item[key] as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }

        return nil
    }

    private func normalizedLine(_ line: String, excluding title: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.caseInsensitiveCompare(title) != .orderedSame else { return nil }
        return trimmed
    }

    private func uniqueStrings(_ values: [String?]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for value in values {
            guard let value else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(trimmed)
        }

        return result
    }

    private func advanceToNextWallpaper(state: inout PersistedState, catalog: CatalogCache) async throws {
        if let cursor = state.historyCursor, cursor < state.history.count - 1 {
            let nextID = state.history[cursor + 1]
            let imageURL = try await downloadImage(id: nextID)

            try await setWallpaper(at: imageURL)

            state.historyCursor = cursor + 1
            state.currentID = nextID
            state.currentImageFilename = imageURL.lastPathComponent
            state.lastUpdatedAt = Date()
            return
        }

        let nextID = try pickRandomUnusedID(from: catalog.ids, history: &state.history)
        let imageURL = try await downloadImage(id: nextID)

        try await setWallpaper(at: imageURL)

        state.currentID = nextID
        state.currentImageFilename = imageURL.lastPathComponent
        state.history.append(nextID)
        state.historyCursor = state.history.count - 1
        state.lastUpdatedAt = Date()
    }

    private func pickRandomUnusedID(from catalog: [Int], history: inout [Int]) throws -> Int {
        guard !catalog.isEmpty else {
            throw EarthLensError.emptyCatalog
        }

        var seen = Set(history)
        if seen.count >= catalog.count {
            history.removeAll()
            seen.removeAll()
        }

        let remaining = catalog.filter { !seen.contains($0) }
        guard let nextID = remaining.randomElement() else {
            throw EarthLensError.emptyCatalog
        }

        return nextID
    }

    private func downloadImage(id: Int) async throws -> URL {
        let destination = AppPaths.imagesDirectory.appendingPathComponent("\(id).jpg")
        if fileManager.fileExists(atPath: destination.path) {
            return destination
        }

        let remoteURL = imageBaseURL.appendingPathComponent("\(id).jpg")
        let (temporaryURL, response) = try await URLSession.shared.download(from: remoteURL)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw EarthLensError.downloadFailed("Image #\(id) was not available.")
        }

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    private func setWallpaper(at imageURL: URL) async throws {
        try await MainActor.run {
            try self.setWallpaperOnMainActor(at: imageURL)
        }
    }

    @MainActor
    private func setWallpaperOnMainActor(at imageURL: URL) throws {
        do {
            for screen in NSScreen.screens {
                try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: [:])
            }
        } catch {
            throw EarthLensError.wallpaperSetFailed(error.localizedDescription)
        }
    }

    private func readCatalogCache() throws -> CatalogCache {
        let data = try Data(contentsOf: AppPaths.catalogCacheFile)
        return try decoder.decode(CatalogCache.self, from: data)
    }

    private func saveCatalogCache(_ catalog: CatalogCache) throws {
        let data = try encoder.encode(catalog)
        try data.write(to: AppPaths.catalogCacheFile, options: .atomic)
    }

    private func loadState() throws -> PersistedState {
        guard fileManager.fileExists(atPath: AppPaths.stateFile.path) else {
            return PersistedState()
        }

        do {
            let data = try Data(contentsOf: AppPaths.stateFile)
            return try decoder.decode(PersistedState.self, from: data)
        } catch {
            throw EarthLensError.stateReadFailed
        }
    }

    private func saveState(_ state: PersistedState) throws {
        let data = try encoder.encode(state)
        try data.write(to: AppPaths.stateFile, options: .atomic)
    }

    private func normalize(_ state: inout PersistedState) {
        defer {
            if !state.setupCompleted && (state.currentID != nil || state.rotationEnabled) {
                state.setupCompleted = true
            }
        }

        guard !state.history.isEmpty else {
            state.historyCursor = nil
            return
        }

        if let cursor = state.historyCursor, state.history.indices.contains(cursor) {
            state.currentID = state.history[cursor]
            if state.currentImageFilename == nil {
                state.currentImageFilename = "\(state.history[cursor]).jpg"
            }
            return
        }

        if let currentID = state.currentID, let matchedIndex = state.history.lastIndex(of: currentID) {
            state.historyCursor = matchedIndex
            if state.currentImageFilename == nil {
                state.currentImageFilename = "\(currentID).jpg"
            }
            return
        }

        state.historyCursor = state.history.count - 1
        state.currentID = state.history[state.history.count - 1]
        if state.currentImageFilename == nil, let currentID = state.currentID {
            state.currentImageFilename = "\(currentID).jpg"
        }
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
