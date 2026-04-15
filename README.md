# EarthLens

A native macOS app that sets stunning Google Earth View satellite images as your desktop wallpaper. Built with SwiftUI and the macOS 26 Liquid Glass design system.

EarthLens rotates through Google Earth View satellite images from around the world, with local catalog caching, wallpaper history, menu bar controls, and optional automatic background rotation through a user LaunchAgent.

## Download

Download the latest DMG from [Releases](https://github.com/Jashanveer/earth-lense/releases).

## Installation

1. Download `EarthLens.dmg` from the latest release.
2. Open the DMG and drag **EarthLens.app** into the **Applications** folder.
3. Launch EarthLens from your Applications folder.
4. EarthLens is not signed/notarized yet, so macOS may block it the first time you open it.
5. If macOS blocks the DMG or app, remove the quarantine attribute and try again:

   ```bash
   sudo xattr -rd com.apple.quarantine ~/Downloads/EarthLens.dmg
   ```

   If you already copied the app to Applications and macOS still blocks it, run:

   ```bash
   sudo xattr -rd com.apple.quarantine /Applications/EarthLens.app
   ```

6. You can also go to **System Settings > Privacy & Security** and choose **Open Anyway** after the first blocked launch.

## First-Time Setup

1. Open **EarthLens** from `/Applications`.
2. Click **Set Up Automatically** on the setup card.
3. If macOS asks for permission to control **System Events** or update the desktop picture, click **OK** or **Allow**.
4. EarthLens installs a user LaunchAgent so wallpaper rotation continues automatically after login.
5. To turn background rotation off later, open EarthLens and disable **Auto-Rotate**.

## Features

- **One-click wallpaper changes** — Move to the next Earth View wallpaper from the main window or menu bar.
- **Previous wallpaper support** — Step back through wallpapers already seen in the current history.
- **Auto-rotate** — Rotate wallpapers automatically in the background every 15 minutes, 30 minutes, 1 hour, or 3 hours.
- **First-time setup guide** — Apply the first wallpaper, create local state/cache files, and install the background LaunchAgent from inside the app.
- **Manual-only mode** — Skip background scheduling and change wallpapers only when you choose.
- **No-repeat rotation cycle** — Tracks seen images and avoids repeats until the available catalog has been used.
- **Menu bar controls** — Change wallpapers, toggle auto-rotate, adjust the interval, reopen the app, or quit from the menu bar.
- **Local catalog and image cache** — Stores runtime state, the Earth View catalog, logs, and downloaded images in Application Support.
- **Native macOS design** — Built with SwiftUI and Liquid Glass for a look that matches macOS 26.
- **Multi-display wallpaper setting** — Applies the selected wallpaper to every connected screen, with AppleScript fallback for desktop Spaces.

## Requirements

- macOS 26 (Tahoe) or later

## Building from Source

1. Make sure Xcode is installed and selected:

   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```

2. Open the project:

   ```bash
   open EarthLens.xcodeproj
   ```

3. Build and run in Xcode (Cmd+R), or build from the command line:

   ```bash
   xcodebuild -project EarthLens.xcodeproj -scheme EarthLens -configuration Release build
   ```

## How It Works

- **Image catalog**: Fetched from the [limhenry/earthview](https://github.com/limhenry/earthview) repository and cached locally. Refreshed automatically if older than 7 days.
- **Wallpaper setting**: Uses `NSWorkspace` to set the desktop picture for each connected screen, with AppleScript/System Events as a fallback.
- **Auto-rotate**: Backed by a user LaunchAgent at `~/Library/LaunchAgents/com.earthlens.wallpaper.plist`.
- **Data storage**: Runtime state is stored in `~/Library/Application Support/EarthLens/`.

## Project Structure

```
EarthLens/
  EarthLens/
    EarthLensApp.swift        # App entry point and lifecycle
    AppModel.swift            # Main view model
    Models/
      AppState.swift          # State types and rotation intervals
    Services/
      AppPaths.swift          # File path management
      EarthLensService.swift  # Image fetching and wallpaper setting
      LaunchAgentService.swift # LaunchAgent install/uninstall
    Views/
      ContentView.swift       # Main UI
      GlassPanel.swift        # Liquid Glass panel component
    Assets.xcassets           # App icons and assets
  Tools/
    GenerateAppIcon.swift     # App icon generation script
```

## License

MIT
