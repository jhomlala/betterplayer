#!/bin/bash
set -e

# We are in the root directory (where better_player/ is checked out)
cd better_player

# Start build in background
echo "Starting Flutter build in background..."
(cd example && flutter build apk --debug --target lib/main_e2e.dart) &
BUILD_PID=$!

# The emulator runner handles the boot wait, but we need to wait for our build
echo "Waiting for build to finish (PID: $BUILD_PID)..."
wait $BUILD_PID

APK_PATH="example/build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK not found at $APK_PATH"
    ls -R example/build/app/outputs/
    exit 1
fi

echo "Installing APK..."
adb install "$APK_PATH"

echo "Running Maestro tests..."
maestro test maestro/android/
