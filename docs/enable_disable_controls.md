---
id: enable_disable_controls
title: Toggle Controls
---

# Toggle Controls

Better Player allows you to programmatically manage the visibility and behavior of the player controls at runtime.

## Enabling and Disabling Controls

You can completely enable or disable all player controls using the `setControlsEnabled` method:

```dart
// Disables all controls (Default is true)
betterPlayerController.setControlsEnabled(false);
```

## Persistent Controls Visibility

By default, controls will fade out after a period of inactivity. You can force the controls to remain visible indefinitely using the `setControlsAlwaysVisible` method:

```dart
// Controls will remain visible on top of the video
betterPlayerController.setControlsAlwaysVisible(true);
```
