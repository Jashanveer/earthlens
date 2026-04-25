# EarthLens 🌍

EarthLens is a signed, native macOS wallpaper app for people who want a quieter,
more beautiful desktop. It brings high-resolution Earth View satellite imagery to
your Mac, then stays out of the way as a refined menu-bar utility.

Built with SwiftUI, sandboxed for the Mac App Store, and designed around the
macOS 26 Liquid Glass visual language.

## Screenshots ✨

![EarthLens main wallpaper preview](AppStore/screenshots/mac/01-earthlens-main.png)

![EarthLens automatic setup screen](AppStore/screenshots/mac/02-earthlens-setup.png)

## Experience

- 🖼 **One-click wallpapers**: set a new Earth View desktop image instantly.
- 🔁 **Auto-rotate**: refresh your wallpaper every 15 minutes, 30 minutes,
  1 hour, or 3 hours.
- 🧭 **Menu-bar first**: EarthLens lives quietly in the menu bar and only shows a
  Dock icon while the main window is open.
- ⏮ **Wallpaper history**: step back through wallpapers from your current
  session.
- 🚀 **Open at login**: Auto-Rotate can register EarthLens as a login item using
  Apple's `SMAppService`.
- 🔒 **Private by design**: no account, no ads, no analytics, no tracking, and no
  backend.
- 💾 **Local cache**: catalog data and downloaded wallpapers stay inside the app
  sandbox.

## Download

Download the latest signed DMG from
[Releases](https://github.com/Jashanveer/earth-lense/releases).

Mac App Store availability is prepared through the files in `AppStore/`.

## Installation

1. Download `EarthLens.dmg` from the latest release.
2. Open the DMG.
3. Drag **EarthLens.app** into **Applications**.
4. Launch EarthLens.

On first launch, EarthLens applies a wallpaper automatically. Enable
**Auto-Rotate** if you want the app to keep refreshing your desktop in the
background.

## Requirements

- macOS 26 Tahoe or later
- Internet access for downloading Earth View catalog data and wallpapers

## Building from Source

1. Install Xcode from the Mac App Store.
2. Open Xcode once and install any required components.
3. Confirm the active developer directory:

   ```bash
   xcode-select -p
   ```

4. Open the project:

   ```bash
   open EarthLens.xcodeproj
   ```

5. Build and run in Xcode with `Cmd+R`, or build from Terminal:

   ```bash
   xcodebuild -project EarthLens.xcodeproj -scheme EarthLens -configuration Release build
   ```

## App Store Package 🍎

The `AppStore/` folder contains the submission materials:

- `AppStore/metadata/en-US/`: app information, version metadata, privacy answers,
  and review notes
- `AppStore/screenshots/mac/`: App Store-ready Mac screenshots
- `AppStore/exportOptions.plist`: export settings for App Store Connect uploads
- `AppStore/submission_checklist.md`: archive and submission checklist

The Release configuration uses:

- Bundle ID: `com.jashanveer.earthlens`
- Version: `2.0`
- Build: `2`
- Team ID: `YLN8JUVVX3`

## Architecture

EarthLens is a single-process, sandboxed macOS app:

- **SwiftUI app lifecycle**: `EarthLensApp` owns the app model, menu-bar item,
  and main window.
- **Hybrid menu-bar behavior**: `LSUIElement = YES` starts the app as a menu-bar
  utility. When the main window opens, EarthLens switches to regular activation
  so it appears in the Dock and Cmd+Tab. Closing the window returns it to the
  menu bar.
- **Wallpaper engine**: `EarthLensService` downloads the catalog and images,
  caches them locally, and applies wallpapers through `NSWorkspace`.
- **Rotation loop**: `AppModel` runs an in-process async rotation task using the
  selected interval.
- **Login item integration**: `LoginItemService` wraps `SMAppService.mainApp`.
- **Sandboxed storage**: state and images live in the app container under
  `~/Library/Containers/com.jashanveer.earthlens/Data/Library/Application Support/EarthLens/`.

## Project Structure

```text
EarthLens/
  EarthLens/
    EarthLensApp.swift          # App entry point and lifecycle
    AppModel.swift              # Main view model and rotation loop
    EarthLens.entitlements      # Sandbox and network entitlements
    PrivacyInfo.xcprivacy       # Apple privacy manifest
    Models/
      AppState.swift            # State types and rotation intervals
    Services/
      AppPaths.swift            # File path management
      EarthLensService.swift    # Catalog, image fetch, and wallpaper setting
      LoginItemService.swift    # SMAppService wrapper
    Views/
      ContentView.swift         # Main UI
      MenuBarMenu.swift         # Menu-bar controls
      GlassPanel.swift          # Liquid Glass panel component
    Assets.xcassets             # App icon and color assets
  AppStore/                     # App Store Connect metadata and screenshots
  Tools/
    GenerateAppIcon.swift       # App icon generation script
  APP_REVIEW_NOTES.md           # App Review notes
  PRIVACY_POLICY.md             # Privacy policy source
  THIRD_PARTY_NOTICES.md        # Earth View and catalog attribution
  LICENSE                       # MIT
```

## How It Works

EarthLens fetches a public Earth View catalog from
[limhenry/earthview](https://github.com/limhenry/earthview), downloads selected
wallpaper images from Google's public Earth View CDN, caches them locally, and
sets the desktop image for each connected screen.

No personal data leaves your Mac.

## Upgrading from a Pre-1.0 Build

Earlier builds installed a LaunchAgent at
`~/Library/LaunchAgents/com.earthlens.wallpaper.plist`. The current signed app
uses `SMAppService` instead.

If you ran a pre-1.0 build, you can remove the old LaunchAgent once:

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.earthlens.wallpaper.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/com.earthlens.wallpaper.plist
```

Previously cached wallpapers and history live at
`~/Library/Application Support/EarthLens/` and are not migrated into the sandbox
container.

## Privacy

EarthLens does not collect personal data, use analytics, show ads, create user
accounts, or run a backend service. See `PRIVACY_POLICY.md` for details.

## License

MIT. See `LICENSE`.
