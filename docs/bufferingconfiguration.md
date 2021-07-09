## Buffering configuration
Buffering of the video can be configurd with `BetterPlayerBufferingConfiguration` class. It allows to setup better buffering experience or setup custom load settings. Currently available only in Android.


`BetterPlayerBufferingConfiguration` should be used within `BetterPlayerDataSource`:

```dart
BetterPlayerDataSource _betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
      bufferingConfiguration: BetterPlayerBufferingConfiguration(
        minBufferMs: 50000,
        maxBufferMs: 13107200,
        bufferForPlaybackMs: 2500,
        bufferForPlaybackAfterRebufferMs: 5000,
      ),
    );
```

Possible configuration options:
```dart
///The default minimum duration of media that the player will attempt to
///ensure is buffered at all times, in milliseconds.
final int minBufferMs;

///The default maximum duration of media that the player will attempt to
///buffer, in milliseconds.
final int maxBufferMs;

///The default duration of media that must be buffered for playback to start
///or resume following a user action such as a seek, in milliseconds.
final int bufferForPlaybackMs;

///The default duration of media that must be buffered for playback to resume
///after a rebuffer, in milliseconds. A rebuffer is defined to be caused by
///buffer depletion rather than a user action.
final int bufferForPlaybackAfterRebufferMs;
```