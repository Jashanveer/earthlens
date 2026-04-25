# Submission Checklist

Before upload:
- Confirm the App Store Connect Bundle ID is `com.jashanveer.earthlens`.
- Host the privacy policy and support page publicly.
- Decide availability territories after reviewing third-party imagery rights.
- Install or let Xcode create Mac App Distribution signing assets.
- Increment `CURRENT_PROJECT_VERSION` for each uploaded build.

Archive and upload from Xcode:
1. Open `EarthLens.xcodeproj`.
2. Select the `EarthLens` scheme and `Any Mac` destination.
3. Product > Archive.
4. In Organizer, choose the archive.
5. Click Distribute App.
6. Select App Store Connect.
7. Validate, then Upload.

Command-line archive:

```sh
xcodebuild archive \
  -project EarthLens.xcodeproj \
  -scheme EarthLens \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$PWD/build/EarthLens.xcarchive" \
  -allowProvisioningUpdates
```

Command-line export after a successful archive:

```sh
xcodebuild -exportArchive \
  -archivePath "$PWD/build/EarthLens.xcarchive" \
  -exportPath "$PWD/build/AppStore" \
  -exportOptionsPlist AppStore/exportOptions.plist \
  -allowProvisioningUpdates
```

