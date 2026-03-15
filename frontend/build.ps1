# Build script for LifeSync Flutter App (PowerShell)
# Usage: .\build.ps1 [debug|release|apk|ios|web]

# Load environment variables from .env file
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)\s*=\s*(.+)\s*$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Remove quotes if present
            $value = $value -replace '^["'']|["'']$',''
            Set-Variable -Name $key -Value $value -Scope Script
        }
    }
}

# Default build type
param(
    [string]$BUILD_TYPE = "apk"
)

Write-Host "🚀 Building LifeSync App..." -ForegroundColor Cyan
Write-Host "Endpoint: $APPWRITE_ENDPOINT"
Write-Host "Project ID: $APPWRITE_PROJECT_ID"
Write-Host "Database: $APPWRITE_DATABASE_ID"

$dartDefines = @(
    "APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT",
    "APPWRITE_PROJECT_ID=$APPWRITE_PROJECT_ID",
    "APPWRITE_DATABASE_ID=$APPWRITE_DATABASE_ID",
    "APPWRITE_HEALTH_IMAGES_BUCKET=$APPWRITE_HEALTH_IMAGES_BUCKET"
)

$dartDefineArgs = $dartDefines | ForEach-Object { "--dart-define", $_ }

switch ($BUILD_TYPE) {
    "debug" {
        flutter run @dartDefineArgs
    }
    "release" {
        flutter build apk --release @dartDefineArgs
    }
    "apk" {
        flutter build apk @dartDefineArgs
    }
    "ios" {
        flutter build ios @dartDefineArgs
    }
    "web" {
        flutter build web @dartDefineArgs
    }
    default {
        Write-Host "Unknown build type: $BUILD_TYPE" -ForegroundColor Red
        Write-Host "Usage: .\build.ps1 [debug|release|apk|ios|web]" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ Build complete!" -ForegroundColor Green
