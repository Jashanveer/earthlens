import SwiftUI

struct MenuBarMenu: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if let title = model.snapshot.currentID.map({ _ in model.snapshot.displayTitle }) {
            Text(title)
                .font(.headline)
        }

        Divider()

        Button("Next Wallpaper", systemImage: "arrow.right") {
            Task { await model.changeWallpaper() }
        }
        .disabled(model.isBusy)
        .keyboardShortcut("N")

        Button("Previous Wallpaper", systemImage: "arrow.left") {
            Task { await model.previousWallpaper() }
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

        Divider()

        Button("Open EarthLens") {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        }
        .keyboardShortcut("O")

        Divider()

        Button("Quit EarthLens") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("Q")
    }
}
