# Third-Party Notices

EarthLens uses the following third-party content and data sources.

## Earth View imagery

Wallpaper images are served from `https://www.gstatic.com/prettyearth/assets/full/`
and are part of the **Google Earth View** project. Imagery is © Google and its
satellite imagery providers (e.g. Maxar, CNES/Airbus, Landsat).

EarthLens displays the imagery on the user's desktop only; it does not
redistribute, modify, or commercially exploit the imagery. End users should
review Google's terms before using the imagery for purposes other than
personal desktop wallpaper:
<https://earthview.withgoogle.com/>

EarthLens is not affiliated with, endorsed by, or sponsored by Google.

## Earth View catalog

The catalog of available Earth View image IDs is fetched from the
community-maintained repository:

- Repo: <https://github.com/limhenry/earthview>
- Maintainer: Henry Lim
- License: MIT

We use only the metadata (IDs and place names) — no source code from that
repository is bundled in the EarthLens app.

## Apple SDKs

EarthLens is built with the Apple-provided SwiftUI, AppKit, and Foundation
frameworks. No additional Swift Package Manager, CocoaPods, or binary SDK
dependencies are bundled.
