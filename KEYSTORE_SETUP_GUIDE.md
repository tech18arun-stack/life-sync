# Android App Signing Setup Guide

## Step 1: Generate Keystore

Run this command in your terminal (from project root):

```bash
keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias lifesync
```

### You'll be prompted for:

1. **Keystore Password**: Choose a strong password (e.g., `LifeSync@2025`)
2. **Re-enter Password**: Confirm the password
3. **First and Last Name**: Your name or organization name
4. **Organizational Unit**: Your department (e.g., "Development")
5. **Organization**: Your company/organization name
6. **City/Locality**: Your city
7. **State/Province**: Your state
8. **Country Code**: IN (for India)
9. **Confirm**: Type "yes"
10. **Key Password**: Press Enter to use same password as keystore, or enter different password

### Example Session:
```
Enter keystore password: LifeSync@2025
Re-enter new password: LifeSync@2025
What is your first and last name?
  [Unknown]:  Your Name
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  Your Company
What is the name of your City or Locality?
  [Unknown]:  Mumbai
What is the name of your State or Province?
  [Unknown]:  Maharashtra
What is the two-letter country code for this unit?
  [Unknown]:  IN
Is CN=Your Name, OU=Development, O=Your Company, L=Mumbai, ST=Maharashtra, C=IN correct?
  [no]:  yes

Enter key password for <lifesync>
        (RETURN if same as keystore password):
```

---

## Step 2: Store Credentials Securely

**IMPORTANT:** Never commit these credentials to Git!

### Create key.properties file:
The file has been created at: `android/key.properties`

**Fill in your actual values:**
- storePassword: Your keystore password
- keyPassword: Your key password (same as store password if you pressed Enter)
- keyAlias: lifesync
- storeFile: keystore.jks

---

## Step 3: Verify Setup

After generating the keystore, verify it exists:
```bash
ls android/app/keystore.jks
```

You should see the file listed.

---

## Step 4: Build Signed AAB/APK

### For AAB (Recommended for Indus App Store):
```bash
flutter build appbundle --release
```

### For APK:
```bash
flutter build apk --release
```

### Output locations:
- **AAB**: `build/app/outputs/bundle/release/app-release.aab`
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`

---

## Important Notes:

1. **Backup your keystore file!** If you lose it, you cannot update your app.
2. **Keep passwords secure** - Store them in a password manager
3. **Never commit** `keystore.jks` or `key.properties` to Git
4. **The .gitignore** file has been updated to exclude these files

---

## Troubleshooting:

### If keytool is not found:
Make sure Java JDK is installed and in your PATH.

**Windows:**
```bash
# Check if Java is installed
java -version

# If not, download from: https://www.oracle.com/java/technologies/downloads/
```

### If build fails:
1. Check that `key.properties` has correct values
2. Verify keystore file exists at `android/app/keystore.jks`
3. Ensure passwords match what you entered during generation

---

## For Indus App Store Upload:

You'll need to provide:
- **Keystore file**: `android/app/keystore.jks`
- **Keystore Password**: [Your password]
- **Key Alias**: lifesync
- **Key Password**: [Your key password]

Keep these credentials safe and accessible for future app updates!
