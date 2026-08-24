---
id: playerbehavioronvisibilitychange
title: Visibility-Based Behavior
---

# Visibility-Based Behavior

Better Player allows you to automatically manage playback states based on the player's visibility within the viewport. This is achieved using the `playerVisibilityChangedBehavior` property.

## Implementation Example (List Usage)

The following example demonstrates how to automatically play or pause a video based on its visibility threshold:

```dart
void onVisibilityChanged(double visibleFraction) async {
    bool isPlaying = await _betterPlayerController.isPlaying() ?? false;
    bool initialized = _betterPlayerController.isVideoInitialized() ?? false;
    
    if (visibleFraction >= widget.playFraction) {
      if (widget.autoPlay && initialized && !isPlaying && !_isDisposing) {
        _betterPlayerController.play();
      }
    } else {
      if (widget.autoPause && initialized && isPlaying && !_isDisposing) {
        _betterPlayerController.pause();
      }
    }
}
```

## Mechanism
This feature operates using a `VisibilityDetector`. The `visibilityFraction` is a value between `0.0` (completely hidden) and `1.0` (fully visible) that describes the extent to which the widget is visible within the viewport.
