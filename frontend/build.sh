#!/bin/bash

# Build script for LifeSync Flutter App
# Usage: ./build.sh [debug|release|apk|ios]

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Default build type
BUILD_TYPE=${1:-apk}

echo "🚀 Building LifeSync App..."
echo "Endpoint: $APPWRITE_ENDPOINT"
echo "Project ID: $APPWRITE_PROJECT_ID"
echo "Database: $APPWRITE_DATABASE_ID"

case $BUILD_TYPE in
    debug)
        flutter run \
            --dart-define=APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT \
            --dart-define=APPWRITE_PROJECT_ID=$APPWRITE_PROJECT_ID \
            --dart-define=APPWRITE_DATABASE_ID=$APPWRITE_DATABASE_ID \
            --dart-define=APPWRITE_HEALTH_IMAGES_BUCKET=$APPWRITE_HEALTH_IMAGES_BUCKET
        ;;
    release)
        flutter build apk --release \
            --dart-define=APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT \
            --dart-define=APPWRITE_PROJECT_ID=$APPWRITE_PROJECT_ID \
            --dart-define=APPWRITE_DATABASE_ID=$APPWRITE_DATABASE_ID \
            --dart-define=APPWRITE_HEALTH_IMAGES_BUCKET=$APPWRITE_HEALTH_IMAGES_BUCKET
        ;;
    apk)
        flutter build apk \
            --dart-define=APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT \
            --dart-define=APPWRITE_PROJECT_ID=$APPWRITE_PROJECT_ID \
            --dart-define=APPWRITE_DATABASE_ID=$APPWRITE_DATABASE_ID \
            --dart-define=APPWRITE_HEALTH_IMAGES_BUCKET=$APPWRITE_HEALTH_IMAGES_BUCKET
        ;;
    ios)
        flutter build ios \
            --dart-define=APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT \
            --dart-define=APPWRITE_PROJECT_ID=$APPWRITE_PROJECT_ID \
            --dart-define=APPWRITE_DATABASE_ID=$APPWRITE_DATABASE_ID \
            --dart-define=APPWRITE_HEALTH_IMAGES_BUCKET=$APPWRITE_HEALTH_IMAGES_BUCKET
        ;;
    web)
        flutter build web \
            --dart-define=APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT \
            --dart-define=APPWRITE_PROJECT_ID=$APPWRITE_PROJECT_ID \
            --dart-define=APPWRITE_DATABASE_ID=$APPWRITE_DATABASE_ID \
            --dart-define=APPWRITE_HEALTH_IMAGES_BUCKET=$APPWRITE_HEALTH_IMAGES_BUCKET
        ;;
    *)
        echo "Unknown build type: $BUILD_TYPE"
        echo "Usage: ./build.sh [debug|release|apk|ios|web]"
        exit 1
        ;;
esac

echo "✅ Build complete!"
