import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot = AppSnapshot.empty
    @Published private(set) var previewImage: NSImage?
    @Published private(set) var isBusy = false
    @Published var statusMessage = "Preparing your Earth View library."
    @Published var errorMessage: String?
    @Published var showsSetupGuide = false

    private let service = EarthLensService()
    private var hasLoaded = false
    private var rotationTask: Task<Void, Never>?
    private var screenChangeTask: Task<Void, Never>?
    private var screenChangeObserver: NSObjectProtocol?

    init() {
        startObservingScreenChanges()

        Task { @MainActor [weak self] in
            await self?.handleAppLaunch()
        }
    }

    func handleAppLaunch() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        // Decide first-run onboarding from persisted state up front, so the setup
        // guide appears even when the very first catalog fetch fails (e.g. offline)
        // and never pops up unexpectedly after a later successful action.
        showsSetupGuide = !Self.persistedSetupCompleted()

        await perform("Loading EarthLens") {
            try await self.service.loadSnapshot()
        }

        if snapshot.currentID == nil {
            await perform("Setting your first wallpaper") {
                try await self.service.setNextWallpaper()
            }
        } else if snapshot.currentImageURL == nil {
            // We have a current scene on record but its cached file is missing
            // (manual delete, reinstall, cache prune) — re-download and re-apply so
            // the desktop doesn't fall back to a blank background.
            await perform("Restoring your wallpaper") {
                try await self.service.reapplyCurrentWallpaper()
            }
        }
    }

    func retryInitialLoad() async {
        hasLoaded = false
        await handleAppLaunch()
    }

    func changeWallpaper() async {
        await perform("Loading the next wallpaper") {
            try await self.service.setNextWallpaper()
        }
    }

    func previousWallpaper() async {
        await perform("Loading the previous wallpaper") {
            try await self.service.setPreviousWallpaper()
        }
    }

    func setAutoRotate(enabled: Bool) async {
        await perform(enabled ? "Enabling auto-rotate" : "Disabling auto-rotate") {
            try await self.service.updateRotation(
                enabled: enabled,
                interval: self.snapshot.rotationInterval,
                advanceImmediately: enabled && !self.snapshot.rotationEnabled
            )
        }
    }

    func setRotationInterval(_ interval: RotationInterval) async {
        await perform("Updating rotation interval") {
            try await self.service.updateRotation(enabled: self.snapshot.rotationEnabled, interval: interval)
        }
    }

    func setOpenAtLogin(enabled: Bool) async {
        await perform(enabled ? "Adding EarthLens to Login Items" : "Removing EarthLens from Login Items") {
            try await self.service.setOpenAtLogin(enabled: enabled)
        }
    }

    func runFirstTimeSetup() async {
        await perform("Setting up EarthLens") {
            try await self.service.configureFirstRun(interval: self.snapshot.rotationInterval)
        }
    }

    func skipFirstTimeSetup() async {
        await perform("Keeping EarthLens in manual mode") {
            try await self.service.markSetupCompleted()
        }
    }

    private func perform(_ message: String, action: @escaping () async throws -> AppSnapshot) async {
        isBusy = true
        statusMessage = message
        errorMessage = nil

        do {
            let newSnapshot = try await action()
            snapshot = newSnapshot
            previewImage = await loadPreviewImage(from: newSnapshot.currentImageURL)
            showsSetupGuide = !newSnapshot.setupCompleted
            statusMessage = makeStatusMessage(for: newSnapshot)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "EarthLens needs attention."
        }

        isBusy = false
        restartRotationLoop()
    }

    private func rotateToNextWallpaper() async {
        await perform("Loading the next wallpaper") {
            try await self.service.setNextWallpaper(fromTimer: true)
        }
    }

    private func loadPreviewImage(from url: URL?) async -> NSImage? {
        guard let url else { return nil }
        // Decode the full-resolution JPEG off the main actor. NSImage isn't Sendable
        // below macOS 14, so hand it back in an unchecked box — the image is created
        // inside the task and never touched there again, so the transfer is safe.
        let boxed = await Task.detached(priority: .utility) {
            UncheckedSendableBox(NSImage(contentsOf: url))
        }.value
        return boxed.value
    }

    private func restartRotationLoop() {
        rotationTask?.cancel()
        guard snapshot.rotationEnabled else {
            rotationTask = nil
            return
        }

        let intervalSeconds = TimeInterval(snapshot.rotationInterval.rawValue)
        rotationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(intervalSeconds))
                guard let self, !Task.isCancelled else { return }
                guard self.snapshot.rotationEnabled else { return }
                if !self.isBusy {
                    await self.rotateToNextWallpaper()
                    return
                }
            }
        }
    }

    private static func persistedSetupCompleted() -> Bool {
        guard
            let data = try? Data(contentsOf: AppPaths.stateFile),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return false
        }
        return (dict["setupCompleted"] as? Bool) ?? false
    }

    private func makeStatusMessage(for snapshot: AppSnapshot) -> String {
        if snapshot.currentID != nil {
            return "Earth View is active."
        }

        return "Ready for the first wallpaper."
    }

    private func startObservingScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scheduleWallpaperReapplyForScreenChange()
            }
        }
    }

    private func scheduleWallpaperReapplyForScreenChange() {
        screenChangeTask?.cancel()
        screenChangeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard let self, !Task.isCancelled, self.snapshot.currentID != nil else { return }
            await self.reapplyCurrentWallpaperForScreenChange()
        }
    }

    private func reapplyCurrentWallpaperForScreenChange() async {
        // Both this path and perform() do load -> mutate -> save on the service;
        // overlapping them can persist a stale cursor/history. Bail if something is
        // already in flight, and hold the busy flag so a rotation tick or user
        // action waits its turn rather than racing this reapply.
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            let newSnapshot = try await service.reapplyCurrentWallpaper()
            guard !Task.isCancelled else { return }
            snapshot = newSnapshot
            previewImage = await loadPreviewImage(from: newSnapshot.currentImageURL)
            statusMessage = makeStatusMessage(for: newSnapshot)
            errorMessage = nil
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
            statusMessage = "EarthLens needs attention."
        }
    }
}

private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}
