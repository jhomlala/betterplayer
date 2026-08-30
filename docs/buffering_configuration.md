---
id: buffering_configuration
title: Buffering Configuration
---

# Buffering Configuration

You can fine-tune the video buffering behavior using the `BufferingConfiguration` class. This allows you to optimize the playback experience based on network conditions or specific application requirements.

:::note
Buffering configuration is currently available only on Android.

:::
## Implementation Example

```dart
PlayerDataSource _betterPlayerDataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
      bufferingConfiguration: BufferingConfiguration(
        minBufferMs: 50000,
        maxBufferMs: 13107200,
        bufferForPlaybackMs: 2500,
        bufferForPlaybackAfterRebufferMs: 5000,
      ),
    );
```

## Configuration Options

*   **`minBufferMs`**: The minimum duration of media (in milliseconds) the player will attempt to keep buffered at all times.
*   **`maxBufferMs`**: The maximum duration of media (in milliseconds) the player will attempt to buffer.
*   **`bufferForPlaybackMs`**: The duration of media that must be buffered before playback starts or resumes after a user action (like seeking).
*   **`bufferForPlaybackAfterRebufferMs`**: The duration of media required to resume playback after an automatic rebuffer (caused by buffer depletion).
