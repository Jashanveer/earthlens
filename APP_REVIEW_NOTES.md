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
   - This registers EarthLens as a login item with `SMAppService.mainApp`.
   - Disable Auto-Rotate to unregister the login item.
5. The menu bar globe icon exposes the same controls.

**Permissions**
- The app is sandboxed and uses the network client entitlement to download
  the public Earth View catalog and selected wallpaper images.
- The app does not request user accounts, location, contacts, files, photos,
  camera, microphone, or tracking permission.

**Data handling**
- No personal data is collected, stored on a server, or shared.
- All app state is stored locally in the app sandbox container under
  `Library/Application Support/EarthLens/`.

**Distribution model**
- This build is for direct user distribution / Mac App Store review.
- See `PRIVACY_POLICY.md` in the repository for the privacy policy URL.
