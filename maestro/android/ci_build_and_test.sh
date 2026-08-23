#!/bin/bash
set -e

# We are in the root directory (where better_player/ is checked out)
cd better_player

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
