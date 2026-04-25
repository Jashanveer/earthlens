# EarthLens

A native macOS app that sets stunning Google Earth View satellite images as
your desktop wallpaper. Built with SwiftUI and the macOS 26 Liquid Glass
design system.

EarthLens runs as a sandboxed hybrid menu-bar agent: a globe icon lives in
the menu bar at the top right of your screen and you can move through
wallpapers manually or have the app rotate them in the background. When you
open the main window, EarthLens also appears in the dock for as long as the
window stays open — close the window and it folds back to the menu bar.

## Download

Download the latest DMG from
[Releases](https://github.com/Jashanveer/earth-lense/releases), or install
from the Mac App Store (coming soon).

## Installation

1. Download `EarthLens.dmg` from the latest release.
2. Open the DMG and drag **EarthLens.app** into the **Applications** folder.
3. Launch EarthLens from your Applications folder.

For unsigned builds, macOS may block the first launch. Right-click the app
and choose **Open**, then **Open** in the dialog. Or, if you've already been
blocked once, go to **System Settings → Privacy & Security** and click
**Open Anyway**.

## First-Time Setup

1. Open **EarthLens** from `/Applications`.
2. The first wallpaper applies automatically.
3. Click **Set Up Automatically** in the setup card to enable Auto-Rotate.
4. macOS will show a notification asking you to allow EarthLens to open at
   login — accept it.
5. To stop background rotation later, open EarthLens (via the menu bar
   globe icon) and disable **Auto-Rotate**.

## Features

- **Menu-bar agent** — EarthLens lives in the menu bar; no dock clutter.
- **One-click wallpaper changes** — Move to the next Earth View wallpaper
  from the main window or menu bar.
- **Previous wallpaper support** — Step back through wallpapers already
  seen in the current history.
- **Auto-rotate** — Rotate wallpapers automatically every 15 minutes,
  30 minutes, 1 hour, or 3 hours, while the app is running.
- **Open at login** — Enabling Auto-Rotate registers EarthLens as a login
  item via `SMAppService`, so rotation continues across restarts.
- **First-time setup guide** — Apply the first wallpaper, create local
  state/cache files, and register the login item from inside the app.
- **Manual-only mode** — Skip background scheduling and change wallpapers
  only when you choose.
- **No-repeat rotation cycle** — Tracks seen images and avoids repeats
  until the available catalog has been used.
- **Local catalog and image cache** — Stores runtime state, the Earth View
  catalog, and downloaded images inside the app's sandbox container.
- **Native macOS design** — Built with SwiftUI and Liquid Glass for a look
  that matches macOS 26.
- **Privacy by design** — No analytics, no tracking, no account, no
  backend. See `PRIVACY_POLICY.md`.

## Requirements

- macOS 26 (Tahoe) or later.

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

## Architecture

EarthLens is a single-process, sandboxed macOS app:

- **Hybrid menu-bar agent** — `LSUIElement = YES` so the app starts as a
  pure menu-bar agent. When the main window opens, the activation policy
  flips to `.regular` (dock icon + Cmd+Tab) and back to `.accessory` when
  the window closes.
- **In-process rotation** — While the app is running, an async `Task` in
  `AppModel` advances the wallpaper on the user's chosen interval.
- **Login item** — Auto-Rotate registers the bundle as a login item via
  `SMAppService.mainApp`, so the menu-bar agent restarts after login.
- **Sandboxed I/O** — Cache and state live inside the app sandbox at
  `~/Library/Containers/com.earthlens.mac/Data/Library/Application Support/EarthLens/`.
- **Wallpaper setting** — `NSWorkspace.setDesktopImageURL(_:for:options:)`
  applies the image to every connected screen on the current Space.
  Multi-Space wallpaper change is a known macOS limitation.

## How It Works

- **Image catalog**: Fetched from the
  [limhenry/earthview](https://github.com/limhenry/earthview) repository
  and cached locally. Refreshed automatically if older than 7 days.
- **Wallpaper setting**: Uses `NSWorkspace` to set the desktop picture for
  each connected screen.
- **Auto-rotate**: Driven by an in-process async loop and re-launched at
  login via `SMAppService`.
- **Data storage**: Runtime state lives in the app's sandbox container,
  resolved through `FileManager.urls(for: .applicationSupportDirectory)`.

## Project Structure

```
EarthLens/
  EarthLens/
    EarthLensApp.swift          # App entry point and lifecycle
    AppModel.swift              # Main view model, rotation loop
    EarthLens.entitlements      # Sandbox + network entitlements
    PrivacyInfo.xcprivacy       # Apple privacy manifest
    Models/
      AppState.swift            # State types and rotation intervals
    Services/
      AppPaths.swift            # File path management
      EarthLensService.swift    # Image fetching and wallpaper setting
      LoginItemService.swift    # SMAppService wrapper for login item
    Views/
      ContentView.swift         # Main UI
      MenuBarMenu.swift         # Menu-bar dropdown
      GlassPanel.swift          # Liquid Glass panel component
    Assets.xcassets             # App icons and assets
  Tools/
    GenerateAppIcon.swift       # App icon generation script
  APP_REVIEW_NOTES.md           # Notes for App Store submission
  PRIVACY_POLICY.md             # Privacy policy (host this URL)
  THIRD_PARTY_NOTICES.md        # Earth View / catalog attribution
  LICENSE                       # MIT
```

## Upgrading from a pre-1.0 build

Earlier builds installed a LaunchAgent at
`~/Library/LaunchAgents/com.earthlens.wallpaper.plist`. The 1.0 release
replaces that with `SMAppService`, but the sandbox prevents the app from
deleting the old plist itself. If you ran a previous build, run this once
in Terminal to clean up:

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.earthlens.wallpaper.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.earthlens.wallpaper.plist
```

Your previously cached wallpapers and history live at
`~/Library/Application Support/EarthLens/` and are not migrated into the
sandbox container; the new build starts with a fresh catalog.

## License

MIT — see `LICENSE`.
