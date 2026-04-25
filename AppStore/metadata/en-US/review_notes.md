# App Review Notes

EarthLens is a sandboxed macOS wallpaper app. It does not require an account,
has no in-app purchases, no advertising, no analytics, and no backend service.

What the app does:
- Downloads a public Earth View catalog.
- Downloads selected Earth View wallpaper images.
- Sets the downloaded image as the desktop wallpaper via `NSWorkspace`.
- Optionally rotates wallpapers on a user-chosen schedule.

Network endpoints contacted:
- `https://raw.githubusercontent.com/limhenry/earthview/master/earthview.json`
- `https://www.gstatic.com/prettyearth/assets/full/<id>.jpg`

How to test:
1. Launch EarthLens.
2. The first wallpaper applies automatically.
3. Click `Next` to advance to another wallpaper.
4. Click `Previous` to return to a previous wallpaper after moving forward.
5. Click `Set Up Automatically` to enable Auto-Rotate.
6. Open the menu bar globe icon to use the same wallpaper controls.
7. Disable Auto-Rotate to unregister the login item.

Permissions and data:
- The app uses the app sandbox and network client entitlement.
- Auto-Rotate registers the app as a login item using `SMAppService.mainApp`.
- No personal data is collected, stored on a server, sold, or shared.
- Local state and cached images are stored only inside the app sandbox
  container under `Library/Application Support/EarthLens/`.

