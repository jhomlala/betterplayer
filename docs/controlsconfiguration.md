# Controls Configuration

The user interface (UI) of the player can be extensively customized using the `BetterPlayerControlsConfiguration` class. This configuration is passed to the `BetterPlayerConfiguration` instance.

## Implementation Example

```dart
var betterPlayerConfiguration = BetterPlayerConfiguration(
    controlsConfiguration: BetterPlayerControlsConfiguration(
        textColor: Colors.white,
        iconsColor: Colors.white,
        controlBarColor: Colors.black.withOpacity(0.7),
    ),
);
```

## Styling & Appearance

*   **`controlBarColor`**: The background color of the control bars.
*   **`textColor`**: The color of all text elements within the controls.
*   **`iconsColor`**: The primary color for all control icons.
*   **`backgroundColor`**: The color of the player background when no video frame is displayed.
*   **`loadingColor`**: The color of the default loading indicator.
*   **`loadingWidget`**: A custom widget to be used instead of the default progress indicator.
*   **`playerTheme`**: Defines the overall theme of the player (e.g., Material, Cupertino).

## Icon Customization

Better Player allows you to override all default icons:
*   `playIcon`, `pauseIcon`, `muteIcon`, `unMuteIcon`
*   `fullscreenEnableIcon`, `fullscreenDisableIcon`
*   `skipBackIcon`, `skipForwardIcon` (Cupertino only)
*   `overflowMenuIcon`, `playbackSpeedIcon`, `subtitlesIcon`, `qualitiesIcon`, `audioTracksIcon`

## Functional Toggles

Enable or disable specific UI features:
*   **`enableFullscreen`**: Toggle the fullscreen button.
*   **`enableMute`**: Toggle the mute button.
*   **`enableProgressText`**: Show/hide the current position and total duration text.
*   **`enableProgressBar`**: Show/hide the seek bar.
*   **`enableProgressBarDrag`**: Enable or disable scrubbing on the progress bar.
*   **`enablePlayPause`**: Toggle the play/pause button.
*   **`enableSkips`**: Toggle the skip forward and skip backward buttons.
*   **`enableOverflowMenu`**: Toggle the overflow menu (contains speed, subtitles, etc.).
*   **`enablePlaybackSpeed`**, `enableSubtitles`, `enableQualities`, `enableAudioTracks`: Toggles for specific overflow menu items.
*   **`enablePip`**: Enable the Picture-in-Picture (PiP) button.
*   **`enableRetry`**: Toggle the retry button on error.

## Progress Bar Styling

Customize the look of the seek bar:
*   **`progressBarPlayedColor`**: Color of the played portion.
*   **`progressBarHandleColor`**: Color of the seek handle (circle).
*   **`progressBarBufferedColor`**: Color of the buffered portion.
*   **`progressBarBackgroundColor`**: Color of the remaining portion of the bar.

## Advanced Control Options

*   **`controlsHideTime`**: The duration of inactivity before controls fade out.
*   **`customControlsBuilder`**: Provide a completely custom widget to handle the player UI.
*   **`showControls`**: Globally show or hide all controls.
*   **`showControlsOnInitialize`**: Show controls immediately upon initialization.
*   **`controlBarHeight`**: Adjust the height of the control bar.
*   **`liveTextColor`**: The color of the "LIVE" indicator text.
*   **`overflowMenuCustomItems`**: A list of `BetterPlayerOverflowMenuItem` to add custom actions to the overflow menu.
*   **`forwardSkipTimeInMilliseconds`**: Adjust the amount of time skipped forward (default: 15s).
*   **`backwardSkipTimeInMilliseconds`**: Adjust the amount of time skipped backward (default: 15s).
*   **`sigmaX`, `sigmaY`**: (iOS only) The quality of the Gaussian Blur applied to the background.

## Dynamic Configuration Updates

You can update the controls configuration at runtime using the `setBetterPlayerControlsConfiguration` method on the `BetterPlayerController`:

```dart
_betterPlayerController.setBetterPlayerControlsConfiguration(
  BetterPlayerControlsConfiguration(
      overflowModalColor: Colors.amberAccent,
  ),
);
```
