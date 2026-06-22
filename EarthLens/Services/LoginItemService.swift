import Foundation
import ServiceManagement

enum LoginItemService {
    static func register() throws {
        try SMAppService.mainApp.register()
    }

    static func unregister() async throws {
        try await SMAppService.mainApp.unregister()
    }

    static var isEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            // `.requiresApproval` means registration succeeded but the user still
            // has to approve EarthLens in System Settings > General > Login Items.
            // Treat it as "on" so the toggle reflects that we asked to launch at
            // login, instead of silently snapping back to off.
            return true
        default:
            return false
        }
    }

    static var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    @MainActor
    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
