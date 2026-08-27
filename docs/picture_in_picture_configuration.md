---
id: picture_in_picture_configuration
title: Picture-in-Picture Configuration
---

# Picture-in-Picture (PiP) Configuration

Picture-in-Picture (PiP) allows users to continue watching videos in a small, floating window while interacting with other parts of the application or system.

## Requirements & Support

PiP support varies significantly by device and operating system version:
*   **iOS**: Requires iOS 14.0 or higher.
*   **Android**: Requires Android 8.0 or higher, sufficient RAM, and the v2 Flutter Android embedding.

### Verification
You can programmatically check if the current device supports PiP:
```dart
bool isSupported = await _betterPlayerController.isPictureInPictureSupported();
```

## Implementation

### 1. Enable PiP Mode
To trigger PiP mode, call the `enablePictureInPicture` method, passing the `GlobalKey` associated with your `BetterPlayer` widget:

```dart
GlobalKey _betterPlayerKey = GlobalKey();

// In your build method:
BetterPlayer(
    controller: _betterPlayerController,
    key: _betterPlayerKey,
)

// To trigger PiP:
_betterPlayerController.enablePictureInPicture(_betterPlayerKey);
```

### 2. Disable PiP Mode
```dart
_betterPlayerController.disablePictureInPicture();
```

## UI Configuration

PiP is enabled by default in both Material and Cupertino controls. You can toggle this feature using the `enablePip` flag in `PlayerControlsConfiguration`. Additionally, you can customize the menu icon using the `pipMenuIcon` property.

## Important Limitations

:::warning
PiP functionality is in an early stage. We recommend thorough testing before deploying to production.

*   **Android**: Enabling PiP will automatically switch the player to fullscreen mode. Disabling PiP may cause a brief orientation flicker as the device returns to its previous settings.
:::
