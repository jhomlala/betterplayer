# Background Audio Mixing

By default, Better Player will interrupt audio from other applications when playback begins. You can modify this behavior to allow Better Player's audio to mix with other active audio sources.

## Implementation

Use the `setMixWithOthers` method on your controller:

```dart
// Enable audio mixing (Default is false)
betterPlayerController.setMixWithOthers(true);
```
