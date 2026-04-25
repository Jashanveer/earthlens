import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ambientBackground
                wallpaperCanvas(size: proxy.size)

                if model.showsSetupGuide {
                    setupGuide(size: proxy.size)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: model.showsSetupGuide)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func wallpaperCanvas(size: CGSize) -> some View {
        let outerPadding: CGFloat = 18
        let cornerRadius: CGFloat = max(24, min(size.width, size.height) * 0.035)

        return ZStack(alignment: .bottomLeading) {
            Group {
                if let previewImage = model.previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.separatorColor)
                    .overlay {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: min(size.width, size.height) * 0.12, weight: .light))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(
                width: max(size.width - outerPadding * 2, 1),
                height: max(size.height - outerPadding * 2, 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 24, y: 12)

            LinearGradient(
                colors: [
                    .black.opacity(0.18),
                    .clear,
                    .black.opacity(0.14),
                    .black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            topLeftStatus
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            embeddedRotationTile(width: min(max((size.width - outerPadding * 2) * 0.25, 280), 360))
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            HStack(alignment: .bottom, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(model.snapshot.displayTitle)
                        .font(.system(size: min(max(size.width * 0.034, 24), 40), weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let subtitle = model.snapshot.displaySubtitle {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        Task { await model.previousWallpaper() }
                    } label: {
                        Label("Previous", systemImage: "arrow.left")
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .disabled(model.isBusy || !model.snapshot.canGoPrevious)

                    Button {
                        Task { await model.changeWallpaper() }
                    } label: {
                        Label("Next", systemImage: "arrow.right")
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(model.isBusy)
                }
            }
            .padding(28)
        }
        .padding(outerPadding)
        .frame(width: size.width, height: size.height)
    }

    private var topLeftStatus: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EarthLens")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                Circle()
                    .fill(model.errorMessage == nil ? Color.green.opacity(0.85) : Color.orange.opacity(0.85))
                    .frame(width: 10, height: 10)

                Text(model.errorMessage ?? model.statusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.clear, in: .capsule)
        }
    }

    private func embeddedRotationTile(width: CGFloat) -> some View {
        GlassPanel(padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Auto-Rotate")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { model.snapshot.rotationEnabled },
                        set: { newValue in
                            Task { await model.setAutoRotate(enabled: newValue) }
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .disabled(model.isBusy)
                }

                Text("Rotate wallpapers automatically in the background.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Picker("Interval", selection: Binding(
                    get: { model.snapshot.rotationInterval },
                    set: { interval in
                        Task { await model.setRotationInterval(interval) }
                    }
                )) {
                    ForEach(RotationInterval.allCases) { interval in
                        Text("\(interval.label) • \(interval.detail)").tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .disabled(model.isBusy)

                Text(model.snapshot.rotationEnabled ? "Background rotation is on." : "Manual mode is on.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: width, alignment: .leading)
        }
    }

    private func setupGuide(size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.28))
                .ignoresSafeArea()

            GlassPanel(padding: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.tint)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Set up EarthLens")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("One guided setup applies your first wallpaper and enables background rotation at login.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        setupStep("Apply your first Earth View wallpaper.")
                        setupStep("Create the local image cache and state files.")
                        setupStep("Add EarthLens to your Login Items so rotation continues after restart.")
                        setupStep("Approve the macOS prompt to allow EarthLens to open at login.")
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task { await model.runFirstTimeSetup() }
                        } label: {
                            Label("Set Up Automatically", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.capsule)
                        .disabled(model.isBusy)

                        Button {
                            Task { await model.skipFirstTimeSetup() }
                        } label: {
                            Text("Manual Only")
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.capsule)
                        .disabled(model.isBusy)
                    }

                    if model.isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(width: min(max(size.width * 0.42, 440), 560), alignment: .leading)
            }
            .padding(24)
        }
    }

    private func setupStep(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green.opacity(0.9))
                .font(.system(size: 14, weight: .semibold))

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ambientBackground: some View {
        Color(.windowBackgroundColor)
            .ignoresSafeArea()
    }
}
