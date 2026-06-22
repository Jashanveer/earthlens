import SwiftUI

struct MenuBarMenu: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if model.snapshot.currentID != nil {
            Text(model.snapshot.displayTitle)
                .font(.headline)

            if let url = model.snapshot.currentEarthViewURL {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Open in Earth View", systemImage: "globe")
                }
            }

            Button {
                model.exportCurrentWallpaper()
            } label: {
                Label("Save Current Wallpaper…", systemImage: "square.and.arrow.down")
            }
            .disabled(model.snapshot.currentImageURL == nil)
        }

        Divider()

        Button {
            Task { await model.changeWallpaper() }
        } label: {
            Label("Next Wallpaper", systemImage: "arrow.right")
        }
        .disabled(model.isBusy)
        .keyboardShortcut("N")

        Button {
            Task { await model.previousWallpaper() }
        } label: {
            Label("Previous Wallpaper", systemImage: "arrow.left")
        }
        .disabled(model.isBusy || !model.snapshot.canGoPrevious)

        Divider()

        Toggle("Auto-Rotate", isOn: Binding(
            get: { model.snapshot.rotationEnabled },
            set: { newValue in
                Task { await model.setAutoRotate(enabled: newValue) }
            }
        ))
        .disabled(model.isBusy)

        if model.snapshot.rotationEnabled {
            Picker("Interval", selection: Binding(
                get: { model.snapshot.rotationInterval },
                set: { interval in
                    Task { await model.setRotationInterval(interval) }
                }
            )) {
                ForEach(RotationInterval.allCases) { interval in
                    Text(interval.label).tag(interval)
                }
            }
            .disabled(model.isBusy)
        }

        Toggle("Open at Login", isOn: Binding(
            get: { model.snapshot.openAtLogin },
            set: { newValue in
                Task { await model.setOpenAtLogin(enabled: newValue) }
            }
        ))
        .disabled(model.isBusy)

        Divider()

        Button("Open EarthLens") {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        }
        .keyboardShortcut("O")

        if shouldShowQuitItem {
            Divider()

            Button("Quit EarthLens") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("Q")
        }
    }

    private var shouldShowQuitItem: Bool {
        NSApp.activationPolicy() != .regular
    }
}
