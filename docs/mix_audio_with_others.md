---
id: mix_audio_with_others
title: Audio Mixing
---

# Background Audio Mixing

By default, Better Player will interrupt audio from other applications when playback begins. You can modify this behavior to allow Better Player's audio to mix with other active audio sources.

## Implementation

Use the `setMixWithOthers` method on your controller:

```dart
// Enable audio mixing (Default is false)
betterPlayerController.setMixWithOthers(true);
```

:::note
On **macOS** and **Windows**, desktop audio subsystems (CoreAudio and WASAPI) mix active audio sources automatically by default. On **Web**, `setMixWithOthers` is ignored as the browser manages audio mixing.
:::
