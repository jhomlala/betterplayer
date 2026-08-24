# Event Listening

Better Player allows you to monitor a wide range of player events, enabling you to react to playback changes programmatically.

## Available Event Types

You can listen for the following `BetterPlayerEventType` values:

*   `initialized`: The video player has successfully initialized.
*   `play`, `pause`: Playback state has changed.
*   `seekTo`: The player has sought to a new position.
*   `openFullscreen`, `hideFullscreen`: Fullscreen state has changed.
*   `setVolume`, `setSpeed`: Audio or playback speed settings have been modified.
*   `progress`: Periodic update of the current playback position.
*   `finished`: The video has reached the end.
*   `exception`: An error occurred during playback.
*   `controlsVisible`, `controlsHiddenStart`, `controlsHiddenEnd`: Visibility of the player UI has changed.
*   `changedSubtitles`, `changedTrack`, `changedResolution`, `changedAudioTracks`: Media stream settings have been updated.
*   `pipStart`, `pipStop`: Picture-in-Picture mode state has changed.
*   `setupDataSource`: A new data source is being configured.
*   `bufferingStart`, `bufferingUpdate`, `bufferingEnd`: The player's buffering status has changed.
*   `changedPlaylistItem`: The current item in a playlist has changed.

## Adding an Event Listener

Once you have initialized your `BetterPlayerController`, you can attach a listener as follows:

```dart
_betterPlayerController.addEventsListener((event) {
    BetterPlayerUtils.log("Better Player Event: ${event.betterPlayerEventType}");
});
```

> [!NOTE]
> Event listeners are automatically removed when the `BetterPlayerController` is disposed.
