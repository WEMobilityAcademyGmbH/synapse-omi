# OMI Mobile v0 — Setup Log

**Mac:** Jonathan's MacBook Pro (Apple Silicon, macOS 26.3)
**Date:** 2026-05-24
**Goal:** Build OMI Flutter App for iOS-Simulator, accept OMI-Cloud-Default
**Status:** ✅ App boots successfully on iPhone 17 Simulator (iOS 26.5)

---

## Prerequisites — what was already installed

| Tool | Pre-existing version | Spec'd minimum | Status |
|---|---|---|---|
| Flutter (Homebrew) | 3.44.0 | 3.35.3 | ⚠️ Too new — caused incompat |
| Xcode | 26.5 (17F42) | 16.4 | ✅ OK |
| CocoaPods | 1.16.2 | 1.16.2 | ✅ OK |
| Opus codec | brew opus | required | ✅ OK |
| iOS Simulator runtime | iOS 26.5 | — | ✅ OK |
| watchOS Simulator runtime | none | required by Watch target | ⚠️ Missing, see workaround |

## What had to be installed/changed

1. **fvm** (Flutter Version Manager): `brew install fvm`
   - Reason: Homebrew Flutter 3.44.0 too new — incompatible with `font_awesome_flutter` (extends `IconData` which became `final` in Dart 3.10+).
2. **Flutter 3.35.3** via `fvm install 3.35.3` + `fvm use 3.35.3 --force`
   - This is the version specced in `setup.sh`.
   - All `flutter` commands from now on use `fvm flutter ...`.

## Errors encountered + fixes

### Error 1: Swift Package Manager — Firebase version conflict
```
firebase_crashlytics-4.3.2 depends on flutterfire 3.11.0-firebase-core-swift
firebase_auth-5.5.3 depends on flutterfire 3.13.0-firebase-core-swift
```
**Fix:** `flutter config --no-enable-swift-package-manager` — falls back to CocoaPods.

### Error 2: `flutter build ios` couldn't find any device
```
No simulator device ID has been set.
A device ID is required to build an app with a watchOS companion app.
```
**Fix:** `flutter devices --device-timeout 20` to detect the booted simulator. Then pass `-d <simulator-id>` explicitly to build.

### Error 3: watchOS 26.5 not installed
```
xcodebuild: error: watchOS 26.5 must be installed in order to run the scheme
```
The Watch target (`omiWatchApp`) is part of the Runner scheme. xcodebuild requires the watchOS SDK even for iOS-simulator builds when a watch companion is configured.

**Fix (workaround):** Removed Watch target from Runner's build phases and dependencies in `ios/Runner.xcodeproj/project.pbxproj`:
- Removed `42A7BA3D2E788BD400138969 /* PBXTargetDependency */` (omiWatchApp) from Runner target dependencies.
- Removed `422906722E75A21E00F49E67 /* Embed Watch Content */` from Runner buildPhases.
- Backup: `ios/Runner.xcodeproj/project.pbxproj.bak`

**Alternative (cleaner):** Install watchOS SDK via `xcodebuild -downloadPlatform watchOS` (4 GB download, ~5–10 min on fast connection). Then no pbxproj edit needed.

### Error 4: `font_awesome_flutter` 10.x incompatible with Flutter 3.44 (Dart 3.10+)
```
Error: The class 'IconData' can't be extended outside of its library because it's a final class.
class IconDataDuotone extends IconData {
```
**Fix:** Downgrade Flutter to specced 3.35.3 via fvm (Dart 3.9.2 — `IconData` still extensible).

Tried before resolving with fvm:
- Pin font_awesome to `10.7.0` — same error.
- Upgrade to `^11.0.0` — many breaking call-site errors (FaIconData ≠ IconData) across 30+ files.

### Warning: SPM-disabled plugin list (informational)
21 plugins (`opus_flutter_ios`, `flutter_sound`, `nordic_dfu`, etc.) don't support SPM. Not blocking — CocoaPods handles them.

## Step durations

| Step | Time |
|---|---|
| Read repo, plan, check prereqs | ~5 min |
| Copy firebase prebuilt configs + .dev.env | < 1 min |
| `flutter pub get` (initial, Flutter 3.44) | ~30 s |
| `pod install --repo-update` | ~3 min (CocoaPods repo update) |
| `dart run build_runner build` | ~55 s |
| First build attempt (failed — SPM) | ~50 s |
| Second build (failed — watchOS) | ~40 s |
| watchOS download attempts | ~5 min (aborted — too slow, > 4 GB) |
| Pbxproj patch (Watch target removal) | ~3 min |
| Third build (failed — font_awesome) | ~3 min |
| fvm install + use 3.35.3 | ~3 min (Flutter SDK download 206 MB) |
| Fourth build with Flutter 3.35.3 + Xcode build (success) | ~2 min |
| simctl install + launch + screenshot | < 30 s |
| **Total** | **~35–45 min wall-clock** |

## Smoke test result

✅ **App launches on iPhone 17 Simulator (iOS 26.5).**
- Bundle ID: `com.friend-app-with-wearable.ios12.development`
- PID at launch: 69002
- Screenshot: `/tmp/omi-mobile-smoke-01.png`
- Visible UI: Onboarding screen "Omi - Ihr KI-Begleiter" with "Loslegen →" button.
- Mock conversation items visible behind the onboarding sheet (likely sample data).
- DEBUG banner top-right (debug build).
- App localized in German (uses system locale).
- Backend: connects to OMI-Cloud default `https://api.omiapi.com/`.

## Files modified (committable changes)

- `app/pubspec.yaml` — font_awesome_flutter pin (reverted to ^10.8.0 after fvm install)
- `app/pubspec.lock` — auto-updated
- `app/ios/Runner.xcodeproj/project.pbxproj` — Watch target dependency + Embed phase removed
- `app/ios/Runner.xcodeproj/project.pbxproj.bak` — original backup
- `app/.fvm/` — fvm-managed Flutter SDK link
- `app/.fvmrc` / `.fvm/fvm_config.json` — pinned to 3.35.3
- `app/.vscode/settings.json` — fvm IDE wiring (auto-generated)
- `app/.dev.env` — local env (must NOT be committed, contains API keys placeholder)
- `app/lib/firebase_options_dev.dart`, `app/lib/firebase_options_prod.dart` — copied from prebuilt
- `app/android/app/src/dev/google-services.json`, `app/android/app/src/prod/google-services.json`
- `app/ios/Config/{Dev,Prod}/GoogleService-Info.plist`, `app/ios/Runner/GoogleService-Info.plist`
- `app/ios/Flutter/Custom.xcconfig` — generated, contains `APP_BUNDLE_IDENTIFIER=com.friend-app-with-wearable.ios12-<hostname>`

## Setup-time estimate for next machine

### Jonathan's other Mac (Apple Silicon)
- If Flutter+Xcode+CocoaPods+brew opus already there: **~15–25 min** (fvm install + Flutter 3.35.3 download + pod install + build).
- From scratch (no Xcode): add 30–60 min for Xcode install + iOS simulator runtime.

### Fabi on Windows
- iOS build is **not possible on Windows.** Fabi can only build Android.
- For Android: `bash setup.sh android` from Git-Bash should work, but the project is iOS-first.
- Recommendation: Fabi runs Android-only or uses a macOS CI runner.

## Known issues / Limitations

- **Watch companion app disabled.** If we want the Apple Watch experience, install watchOS SDK and revert pbxproj.
- **Firebase prebuilt config** is the BasedHardware default (`based-hardware-dev`) — auth flows go through BasedHardware's Firebase project. Cannot easily swap to our own without `flutterfire config` re-run.
- **`backend_url.dart` (custom backend form) is a UI stub** — it doesn't actually persist or apply the entered URL. See `ENDPOINT_POINTING_NOTES.md` for the real wiring path.
- **App requires Firebase auth to proceed past onboarding.** Without Firebase project association, sign-in will fail.
