import Foundation

enum RotationInterval: Int, CaseIterable, Codable, Identifiable {
    case fifteenMinutes = 900
    case thirtyMinutes = 1_800
    case hourly = 3_600
    case threeHours = 10_800

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fifteenMinutes:
            return "15 min"
        case .thirtyMinutes:
            return "30 min"
        case .hourly:
            return "1 hour"
        case .threeHours:
            return "3 hours"
        }
    }

    var detail: String {
        switch self {
        case .fifteenMinutes:
            return "Fast rotation"
        case .thirtyMinutes:
            return "Balanced cadence"
        case .hourly:
            return "Minimal interruption"
        case .threeHours:
            return "Slow ambient mode"
        }
    }
}

struct PersistedState: Codable {
    var history: [Int] = []
    var historyCursor: Int?
    var currentID: Int?
    var currentImageFilename: String?
    var rotationEnabled = false
    var rotationInterval: RotationInterval = .thirtyMinutes
    var lastUpdatedAt: Date?
    var setupCompleted = false

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        history = try container.decodeIfPresent([Int].self, forKey: .history) ?? []
        historyCursor = try container.decodeIfPresent(Int.self, forKey: .historyCursor)
        currentID = try container.decodeIfPresent(Int.self, forKey: .currentID)
        currentImageFilename = try container.decodeIfPresent(String.self, forKey: .currentImageFilename)
        rotationEnabled = try container.decodeIfPresent(Bool.self, forKey: .rotationEnabled) ?? false
        rotationInterval = try container.decodeIfPresent(RotationInterval.self, forKey: .rotationInterval) ?? .thirtyMinutes
        lastUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .lastUpdatedAt)
        setupCompleted = try container.decodeIfPresent(Bool.self, forKey: .setupCompleted) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case history
        case historyCursor
        case currentID
        case currentImageFilename
        case rotationEnabled
        case rotationInterval
        case lastUpdatedAt
        case setupCompleted
    }
}

struct EarthViewEntry: Codable, Hashable {
    var id: Int
    var title: String?
    var subtitle: String?
}

struct CatalogCache: Codable {
    var entries: [EarthViewEntry]
    var fetchedAt: Date

    var ids: [Int] {
        entries.map(\.id)
    }

    init(entries: [EarthViewEntry], fetchedAt: Date) {
        self.entries = entries
        self.fetchedAt = fetchedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)

        if let entries = try container.decodeIfPresent([EarthViewEntry].self, forKey: .entries) {
            self.entries = entries
        } else {
            let ids = try container.decodeIfPresent([Int].self, forKey: .ids) ?? []
            self.entries = ids.map { EarthViewEntry(id: $0, title: nil, subtitle: nil) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
        try container.encode(fetchedAt, forKey: .fetchedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case entries
        case ids
        case fetchedAt
    }
}

struct AppSnapshot {
    var totalCount: Int
    var seenCount: Int
    var remainingCount: Int
    var currentID: Int?
    var currentImageURL: URL?
    var catalogUpdatedAt: Date?
    var rotationEnabled: Bool
    var rotationInterval: RotationInterval
    var canGoPrevious: Bool
    var canGoForward: Bool
    var displayTitle: String
    var displaySubtitle: String?
    var setupCompleted: Bool

    var currentEarthViewURL: URL? {
        guard let currentID else { return nil }
        return URL(string: "https://earthview.withgoogle.com/\(currentID)")
    }

    static let empty = AppSnapshot(
        totalCount: 0,
        seenCount: 0,
        remainingCount: 0,
        currentID: nil,
        currentImageURL: nil,
        catalogUpdatedAt: nil,
        rotationEnabled: false,
        rotationInterval: .thirtyMinutes,
        canGoPrevious: false,
        canGoForward: false,
        displayTitle: "Ready for a first wallpaper",
        displaySubtitle: "Load the first scene to start the gallery.",
        setupCompleted: false
    )
}

enum EarthLensError: LocalizedError {
    case emptyCatalog
    case invalidCatalog
    case downloadFailed(String)
    case wallpaperSetFailed(String)
    case stateReadFailed
    case noPreviousWallpaper

    var errorDescription: String? {
        switch self {
        case .emptyCatalog:
            return "The Earth View catalog is empty."
        case .invalidCatalog:
            return "The remote catalog format could not be parsed."
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .wallpaperSetFailed(let message):
            return "Could not apply the wallpaper: \(message)"
        case .stateReadFailed:
            return "The local EarthLens state could not be read."
        case .noPreviousWallpaper:
            return "There isn't a previous wallpaper yet."
        }
    }
}
