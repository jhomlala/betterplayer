## Player behavior on visibility change
You can change player behavior if player is not visible by using `playerVisibilityChangedBehavior` option from `BetterPlayerConfiguration`.
Here is an example for player used in list:

```dart
void onVisibilityChanged(double visibleFraction) async {
    bool isPlaying = await _betterPlayerController.isPlaying();
    bool initialized = _betterPlayerController.isVideoInitialized();
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

Player behavior works in the basis of `VisibilityDetector` (it uses `visibilityFraction`, which is value from 0.0 to 1.0 that describes how much given widget is on the viewport). So if value 0.0, player is not visible, so we need to pause the video. If the `visibilityFraction` is 1.0, we need to play it again.
