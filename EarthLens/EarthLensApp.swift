import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Already configured? Run as menu-bar agent only — close any window
        // SwiftUI auto-opened. The user can re-open via the menu bar item.
        guard hasCompletedSetup() else { return }
        for window in NSApp.windows where window.canBecomeMain {
            window.close()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        true
    }

    private func hasCompletedSetup() -> Bool {
        guard
            let data = try? Data(contentsOf: AppPaths.stateFile),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return false
        }
        return (dict["setupCompleted"] as? Bool) ?? false
    }
}

@main
struct EarthLensApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    init() {
        try? AppPaths.ensureDirectories()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(model)
        }
        .defaultSize(width: 1_180, height: 780)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        MenuBarExtra("EarthLens", systemImage: "globe.americas.fill") {
            MenuBarMenu()
                .environmentObject(model)
        }
    }
}
