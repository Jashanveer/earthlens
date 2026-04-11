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

    func handleAppLaunch() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        await perform("Syncing local catalog") {
            try await self.service.reconcileSchedulePathIfNeeded()
        }

        if snapshot.currentID == nil {
            await perform("Setting your first wallpaper") {
                try await self.service.setNextWallpaper()
            }
        }
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
            previewImage = newSnapshot.currentImageURL.flatMap(NSImage.init(contentsOf:))
            showsSetupGuide = !newSnapshot.setupCompleted
            statusMessage = makeStatusMessage(for: newSnapshot)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "EarthLens needs attention."
        }

        isBusy = false
    }

    private func makeStatusMessage(for snapshot: AppSnapshot) -> String {
        if snapshot.currentID != nil {
            return "Earth View is active."
        }

        return "Ready for the first wallpaper."
    }
}
