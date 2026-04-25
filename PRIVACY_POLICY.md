# EarthLens Privacy Policy

_Last updated: April 24, 2026_

EarthLens is a macOS app that sets satellite imagery from Google Earth View
as your desktop wallpaper. This document describes what data the app does and
does not handle.

## Summary

- **EarthLens does not collect, transmit, or sell any personal data.**
- EarthLens does not contain analytics, advertising, or tracking SDKs.
- All app state stays on your Mac, inside the app sandbox container under
  `Library/Application Support/EarthLens/`.

## Data the app stores locally

EarthLens writes the following files inside the app sandbox container's
Application Support directory:

- `state.json` — wallpaper history, current wallpaper ID, rotation settings.
- `catalog-cache.json` — cached list of Earth View image IDs and titles.
- `Images/` — downloaded wallpaper JPEG files (one per wallpaper viewed).
- `earthlens.log` — local diagnostic log capped at ~256 KB; not transmitted.

These files never leave your device. Deleting the EarthLens app and the
`EarthLens` folder above removes all locally stored data.

## Network requests

To function, EarthLens makes outbound HTTPS requests to:

- `https://raw.githubusercontent.com/limhenry/earthview/master/earthview.json`
  — to download the public Earth View catalog (refreshed about once a week).
- `https://www.gstatic.com/prettyearth/assets/full/<id>.jpg`
  — to download each wallpaper image you view.

These requests are made directly from your Mac to GitHub and Google's
public CDNs. Your IP address and standard HTTP headers are visible to those
operators under their own privacy policies. EarthLens does not send any
account, identifier, telemetry, or usage data of its own.

EarthLens does not run a backend server. There is no EarthLens account, no
sign-in, and no data sent to the developer.

## System permissions

EarthLens is sandboxed and uses macOS system APIs to set your desktop
wallpaper. It does not request access to your location, contacts, files,
photos, camera, microphone, or tracking permission.

If you enable Auto-Rotate, EarthLens registers itself as a login item using
Apple's `SMAppService` API so wallpaper rotation can resume after login. This
is disabled when you turn Auto-Rotate off inside the app.

## Children

EarthLens is not directed to children. We do not knowingly process data from
children.

## Changes

If this policy is updated, the new version will replace this file in the
EarthLens repository on GitHub.

## Contact

Questions about this policy can be sent to the email address listed on the
EarthLens GitHub repository.
