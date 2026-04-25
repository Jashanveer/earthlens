# App Review Notes — EarthLens

Paste a tailored version of this into the **App Review Information → Notes**
field in App Store Connect when submitting.

---

EarthLens is a single-window macOS wallpaper app. It does not require an
account, has no in-app purchases, no advertising, and no analytics. There is
no backend service.

**What the app does**
- Downloads satellite imagery from the public Google Earth View CDN.
- Sets the downloaded image as the desktop wallpaper via `NSWorkspace`.
- Optionally rotates the wallpaper on a user-chosen schedule.

**Network endpoints contacted**
- `https://raw.githubusercontent.com/limhenry/earthview/master/earthview.json`
  (public Earth View catalog, refreshed weekly)
- `https://www.gstatic.com/prettyearth/assets/full/<id>.jpg`
  (Google's public Earth View imagery CDN)

**How to test**
1. Launch EarthLens.
2. The first wallpaper is applied automatically.
3. Click **Next** to advance to the next wallpaper, **Previous** to go back.
4. Click **Set Up Automatically** in the setup card to enable Auto-Rotate.
   - This installs a user LaunchAgent at
     `~/Library/LaunchAgents/com.earthlens.wallpaper.plist`.
   - Disable Auto-Rotate to remove the LaunchAgent.
5. The menu bar globe icon exposes the same controls.

**Permissions**
- The app may request automation access for **System Events** the first time
  it falls back to AppleScript for wallpaper setting. This prompt is
  triggered by macOS, not by the developer, and is optional.

**Data handling**
- No personal data is collected, stored on a server, or shared.
- All app state is in `~/Library/Application Support/EarthLens/`.

**Distribution model**
- This build is for direct user distribution / Mac App Store review.
- See `PRIVACY_POLICY.md` in the repository for the privacy policy URL.
