#!/bin/bash
set -e

# The script assumes it is run from the repository root.
# If not, we try to find the root based on the script location.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

if [ "$PWD" != "$REPO_ROOT" ]; then
    echo "Changing directory to repository root: $REPO_ROOT"
    cd "$REPO_ROOT"
fi

# Build APK in background if not already started, or just wait for it
# In the new workflow, we might start it before calling this script
if [ -z "$BUILD_PID" ]; then
    echo "Starting Flutter build in background..."
    (cd example && flutter build apk --debug --target lib/main_e2e.dart) &
    BUILD_PID=$!
fi

echo "Waiting for Android Emulator to boot..."
# Wait for adb to see the device
until adb shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; do
  echo "Emulator is still booting..."
  sleep 5
done

echo "Emulator booted!"

# Wait for system to settle
echo "Waiting for system UI and package manager to settle (30s)..."
sleep 30

# Ensure screen is unlocked
echo "Unlocking screen..."
adb shell input keyevent 82
adb shell wm dismiss-keyguard

# Disable animations for faster testing
echo "Disabling animations..."
adb shell settings put global window_animation_scale 0.0
adb shell settings put global transition_animation_scale 0.0
adb shell settings put global animator_duration_scale 0.0

echo "Waiting for Flutter build to finish (PID: $BUILD_PID)..."
if ! wait $BUILD_PID; then
    echo "Error: Flutter build failed!"
    exit 1
fi

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
