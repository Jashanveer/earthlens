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
        SMAppService.mainApp.status == .enabled
    }

    static var status: SMAppService.Status {
        SMAppService.mainApp.status
    }
}
