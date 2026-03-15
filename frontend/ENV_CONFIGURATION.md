# LifeSync Environment Configuration

This document explains how to configure environment variables for the LifeSync Flutter app.

## 📋 Overview

LifeSync uses environment variables to manage configuration securely across different environments (development, staging, production).

## 🔧 Configuration Methods

### Method 1: Using `.env` File (Recommended for Development)

1. **Copy the example file**:
   ```bash
   cd frontend
   cp .env.example .env
   ```

2. **Edit `.env`** with your values:
   ```bash
   APPWRITE_ENDPOINT=https://api.edizo.in/v1
   APPWRITE_PROJECT_ID=your_project_id_here
   APPWRITE_DATABASE_ID=Life_db
   APPWRITE_HEALTH_IMAGES_BUCKET=health-images
   APPWRITE_API_KEY=your_api_key_here  # Server-side only!
   ```

3. **Build using the build script**:
   ```bash
   # Windows PowerShell
   .\build.ps1 release

   # Linux/Mac
   ./build.sh release
   ```

### Method 2: Using `--dart-define` (Recommended for CI/CD)

Pass configuration directly when building:

```bash
flutter build apk --release \
  --dart-define=APPWRITE_ENDPOINT=https://api.edizo.in/v1 \
  --dart-define=APPWRITE_PROJECT_ID=your_project_id \
  --dart-define=APPWRITE_DATABASE_ID=Life_db \
  --dart-define=APPWRITE_HEALTH_IMAGES_BUCKET=health-images
```

### Method 3: Environment Variables (For Scripts)

```bash
# Linux/Mac
export APPWRITE_ENDPOINT=https://api.edizo.in/v1
export APPWRITE_PROJECT_ID=your_project_id
python database/setup_appwrite_schema.py

# Windows PowerShell
$env:APPWRITE_ENDPOINT="https://api.edizo.in/v1"
$env:APPWRITE_PROJECT_ID="your_project_id"
python database/setup_appwrite_schema.py
```

## 🔐 Security Best Practices

### ✅ DO:
- Use `.env` for local development only
- Add `.env` to `.gitignore` (already done)
- Use `--dart-define` for CI/CD pipelines
- Keep API keys secret and rotate them regularly
- Use different projects for dev/staging/production

### ❌ DON'T:
- Commit `.env` files to version control
- Hardcode sensitive values in source code
- Share API keys in public repositories
- Use production keys in development

## 📦 Environment Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `APPWRITE_ENDPOINT` | Appwrite API endpoint URL | `https://api.edizo.in/v1` | ✅ |
| `APPWRITE_PROJECT_ID` | Appwrite Project ID (from Console) | - | ✅ |
| `APPWRITE_DATABASE_ID` | Appwrite Database ID | `Life_db` | ✅ |
| `APPWRITE_HEALTH_IMAGES_BUCKET` | Storage bucket for health images | `health-images` | ✅ |
| `APPWRITE_API_KEY` | Server API key (for setup scripts only) | - | ✅ (scripts only) |

## 🚀 Build Commands

### Development (Debug)
```bash
# Windows
.\build.ps1 debug

# Linux/Mac
./build.sh debug
```

### Production (Release APK)
```bash
# Windows
.\build.ps1 release

# Linux/Mac
./build.sh release
```

### Web Build
```bash
# Windows
.\build.ps1 web

# Linux/Mac
./build.sh web
```

## 📱 Getting Your Appwrite Credentials

1. **Project ID**: 
   - Go to Appwrite Console → Project Settings → General
   - Copy the Project ID

2. **Database ID**:
   - Go to Appwrite Console → Databases
   - Click on your database
   - Copy the Database ID

3. **API Key** (Server-side only):
   - Go to Appwrite Console → Settings → API Keys
   - Create new API key with required scopes
   - Copy and store securely

4. **Storage Bucket ID**:
   - Go to Appwrite Console → Storage
   - Click on your bucket
   - Copy the Bucket ID

## 🔍 Verifying Configuration

After building, verify the configuration is correct:

```bash
# Check if environment variables are loaded
flutter run --verbose

# Check build output for dart-define values
flutter build apk --release --verbose
```

## 🆘 Troubleshooting

### App not connecting to Appwrite?
- Verify `APPWRITE_ENDPOINT` is correct (include `/v1`)
- Check if your device/emulator can reach the endpoint
- For Tailscale networks, ensure device is connected

### Build fails with "Unresolved reference"?
- Run `flutter clean`
- Run `flutter pub get`
- Try building again

### API Key permission errors?
- Ensure API key has required scopes
- Don't use API key in Flutter app (server-side only!)
- Check Appwrite Console → Settings → API Keys

## 📚 Additional Resources

- [Appwrite Documentation](https://appwrite.io/docs)
- [Flutter Environment Variables](https://docs.flutter.dev/deployment/flavors)
- [Dart Environment Variables](https://api.flutter.dev/flutter/dart-io/Platform/environment.html)
