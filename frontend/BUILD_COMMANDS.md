# LifeSync - Build & Deployment Commands

This document contains a quick reference guide for all the essential Flutter commands you will need to build, test, and release the LifeSync application.

---

## 🏗️ 1. Standard Testing & Running
Run the app in debug mode on your connected device or emulator. The `--dart-define-from-file=.env` flag is **required** so the app can talk to Appwrite and fetch your `config.json`.

```bash
# Run on connected device (Debug Mode)
flutter run --dart-define-from-file=.env

# Run on connected device (Release Mode)
flutter run --release --dart-define-from-file=.env
```

---

## 📦 2. Building APKs for Android

### The Standard Release APK (Fat APK)
This builds a single, large APK that contains the binaries for *all* Android device architectures. It is usually >60 MB and exceeds GitHub's 25MB direct-upload limit.
```bash
flutter build apk --dart-define-from-file=.env
```
👉 **Location:** `build\app\outputs\flutter-apk\app-release.apk`

### Split APKs (Recommended for Uploads)
This command splits the app into separate, smaller APKs tailored for specific processor architectures (like `arm64-v8a` which is used by 99% of modern Android phones). These are usually ~25 MB and are perfect for uploading to standard cloud storage brackets or GitHub.
```bash
flutter build apk --split-per-abi --dart-define-from-file=.env
```
👉 **Locations:** 
- `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` *(Use this one for modern phones!)*
- `build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk` *(For older phones)*
- `build\app\outputs\flutter-apk\app-x86_64-release.apk` *(For emulators)*

### Android App Bundle (AAB - For Google Play Store)
If you ever decide to publish LifeSync to the Google Play Store, you must build an AAB instead of an APK.
```bash
flutter build appbundle --dart-define-from-file=.env
```
👉 **Location:** `build\app\outputs\bundle\release\app-release.aab`

---

## 📲 3. Installing Built APKs Directly to Device
If you have already built the APK and just want to install it on your plugged-in Android device without rebuilding.

```bash
# Install the standard release APK
flutter install --release

# Note: If flutter install fails or you built split APKs, use ADB directly:
adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

---

## 🧹 4. Cleaning & Troubleshooting
If you encounter strange Gradle errors, build failures, or dependency conflicts, cleaning the project cache is the best first step.

```bash
# Deletes the /build/ directory to ensure a completely fresh compilation
flutter clean

# Re-downloads all your pubspec packages cleanly
flutter pub get
```

---

## 🌍 5. Remote Configuration & Updates
Whenever you rebuild the app to distribute a new update:

1. Copy your new `app-arm64-v8a-release.apk` to your **Appwrite Storage** bucket.
2. Get the new direct download link for that file.
3. Open your remote `config.json` repository on GitHub.
4. Increment the `latest_version` (e.g., from `"2.1.10"` -> `"2.1.11"`).
5. Paste your new Appwrite link into the `download_url` property.
6. **Commit** the changes to your `main` branch. 
7. Within a few hours (or immediately if users restart), the app will detect the new version and launch the new **In-App Updater**!
