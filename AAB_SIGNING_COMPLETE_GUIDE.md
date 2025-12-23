# 🔐 Complete AAB Signing Setup for Indus App Store

## ✅ What's Already Done

1. ✓ build.gradle.kts configured for signing
2. ✓ key.properties.template created
3. ✓ .gitignore already excludes keystore files

---

## 📋 Step-by-Step Instructions

### Step 1: Generate Keystore File

Open PowerShell/Command Prompt in your project root and run:

```powershell
cd "C:\Users\tech1\Desktop\family management"
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android\app\keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lifesync -dname "CN=arun&co, OU=Development, O=Arun@process, L=Rasipuram, ST=TamilNadu, C=IN"
```

**You'll be asked for:**

1. **Enter keystore password:** 
   - Choose a strong password (e.g., `LifeSync@2025!`)
   - Remember this - you'll need it!

2. **Re-enter new password:**
   - Type the same password again

3. **Enter key password for <lifesync>**
    - Press ENTER to use the same password as keystore

---

### Step 2: Create key.properties File

1. Copy the template file:
   ```powershell
   copy key.properties.template android\key.properties
   ```

2. Open `android\key.properties` in a text editor

3. Replace the placeholders with your actual values:
   ```properties
   storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   keyAlias=lifesync
   storeFile=keystore.jks
   ```

   **Example:**
   ```properties
   storePassword=LifeSync@2025!
   keyPassword=LifeSync@2025!
   keyAlias=lifesync
   storeFile=keystore.jks
   ```

4. Save the file

---

### Step 3: Verify Setup

Check that these files exist:

```powershell
# Check keystore file
dir android\app\keystore.jks

# Check key.properties
dir android\key.properties
```

Both files should be listed.

---

### Step 4: Build Signed AAB

Now build your signed release AAB:

```powershell
flutter build appbundle --release
```

**Output location:**
```
build\app\outputs\bundle\release\app-release.aab
```

---

### Step 5: Build Signed APK (Optional)

If you also need an APK:

```powershell
flutter build apk --release
```

**Output location:**
```
build\app\outputs\flutter-apk\app-release.apk
```

---

## 📤 For Indus App Store Upload

When uploading to Indus App Store, you'll need:

### 1. Upload the AAB file:
   - File: `build\app\outputs\bundle\release\app-release.aab`

### 2. Provide signing details:
   - **Keystore file**: `android\app\keystore.jks`
   - **Keystore Password**: [Your password from Step 1]
   - **Key Alias**: `lifesync`
   - **Key Password**: [Your key password from Step 1]

---

## 🔒 Security Checklist

- [x] Keystore file generated
- [ ] Passwords are strong and secure
- [ ] Passwords saved in password manager
- [x] key.properties file created with actual values
- [ ] Keystore file backed up to secure location
- [ ] Never commit keystore.jks to Git
- [ ] Never commit key.properties to Git

---

## 💾 Backup Your Keystore!

**CRITICAL:** Make a backup of these files:
- `android\app\keystore.jks`
- Your passwords (in password manager)

**Store backups in:**
- External hard drive
- Cloud storage (encrypted)
- USB drive (in safe place)

**Why?** If you lose your keystore, you CANNOT update your app on the store!

---

## 🐛 Troubleshooting

### Error: "keytool is not recognized"

**Solution:** Install Java JDK

1. Download Java JDK from: https://www.oracle.com/java/technologies/downloads/
2. Install it
3. Add to PATH or use full path:
   ```powershell
   "C:\Program Files\Java\jdk-XX\bin\keytool.exe" -genkey ...
   ```

### Error: "Keystore file does not exist"

**Solution:** Make sure you ran the keytool command from project root

### Error: "Build failed - signing config"

**Solution:** Check that:
1. `android\key.properties` exists
2. `android\app\keystore.jks` exists
3. Passwords in key.properties are correct
4. No typos in key.properties

### Error: "Incorrect password"

**Solution:** 
1. Double-check passwords in key.properties
2. Make sure there are no extra spaces
3. Passwords are case-sensitive

---

## 📝 Quick Reference

### File Locations:
```
android/
├── app/
│   └── keystore.jks          ← Your keystore file
└── key.properties            ← Your credentials (DO NOT COMMIT!)

key.properties.template       ← Template (safe to commit)
```

### Build Commands:
```powershell
# Build AAB (for app stores)
flutter build appbundle --release

# Build APK (for direct distribution)
flutter build apk --release

# Build APK split by ABI (smaller files)
flutter build apk --split-per-abi --release
```

### Output Locations:
```
build/app/outputs/
├── bundle/release/
│   └── app-release.aab       ← Upload this to Indus App Store
└── flutter-apk/
    ├── app-release.apk       ← Universal APK
    ├── app-armeabi-v7a-release.apk
    ├── app-arm64-v8a-release.apk
    └── app-x86_64-release.apk
```

---

## ✅ Verification Steps

After building, verify your AAB:

```powershell
# Check file size (should be 20-40 MB)
dir build\app\outputs\bundle\release\app-release.aab

# Check file exists
if (Test-Path "build\app\outputs\bundle\release\app-release.aab") {
    Write-Host "✓ AAB file created successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ AAB file not found!" -ForegroundColor Red
}
```

---

## 🎯 Next Steps After Building

1. [ ] Test the release APK on a real device
2. [ ] Verify all features work in release mode
3. [ ] Check app size is acceptable
4. [ ] Prepare screenshots for app store
5. [ ] Upload AAB to Indus App Store
6. [ ] Provide signing credentials when prompted

---

## 📞 Need Help?

If you encounter issues:

1. Check the error message carefully
2. Verify all file paths are correct
3. Ensure Java JDK is installed
4. Make sure passwords match
5. Try cleaning and rebuilding:
   ```powershell
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

---

**Created:** December 6, 2025  
**Version:** 1.0.0  
**Status:** Ready to use ✓
