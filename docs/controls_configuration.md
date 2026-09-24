---
id: controls_configuration
title: Controls Configuration
---

# Controls Configuration

The user interface (UI) of the player can be extensively customized using the `PlayerControlsConfiguration` class. This configuration is passed to the `PlayerConfiguration` instance.

## Implementation Example

```dart
var betterPlayerConfiguration = PlayerConfiguration(
    controlsConfiguration: PlayerControlsConfiguration(
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
*   `overflowMenuIcon`, `pipMenuIcon`, `playbackSpeedIcon`, `subtitlesIcon`, `qualitiesIcon`, `audioTracksIcon`

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
*   **`enableReplay`**: Show/hide the replay button when the video ends.


## Progress Bar Styling

Customize the look of the seek bar:
*   **`progressBarPlayedColor`**: Color of the played portion.
*   **`progressBarHandleColor`**: Color of the seek handle (circle).
*   **`progressBarBufferedColor`**: Color of the buffered portion.
*   **`progressBarBackgroundColor`**: Color of the remaining portion of the bar.

## Advanced Control Options

*   **`controlsHideTime`**: The duration of inactivity before controls fade out.
*   **`controlsTransitionTime`**: The duration of the transition animation.
*   **`customControlsBuilder`**: Provide a completely custom widget to handle the player UI. **Note**: This will only be used if `playerTheme` is set to `PlayerTheme.custom`.
    > [!IMPORTANT]
    > When using `customControlsBuilder` with `PlayerTheme.custom`, you are entirely responsible for managing your custom widget's state, visibility timers, animations, tap detectors, and interaction handling (such as auto-hiding or responding to `onControlsVisibilityChanged`). Unlike the built-in Material or Cupertino themes, Better Player does not automatically wrap or animate custom widgets in fade transitions or hide timers.
*   **`showControls`**: Globally show or hide all controls.
*   **`showControlsOnInitialize`**: Show controls immediately upon initialization.
*   **`controlBarHeight`**: Adjust the height of the control bar.
*   **`liveTextColor`**: The color of the "LIVE" indicator text.
*   **`overflowMenuCustomItems`**: A list of `PlayerOverflowMenuItem` to add custom actions to the overflow menu.
*   **`playbackSpeeds`**: Define a custom list of speeds available in the playback speed menu (default: `[0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]`).
*   **`forwardSkipTimeInMilliseconds`**: Adjust the amount of time skipped forward (default: 15s).
*   **`backwardSkipTimeInMilliseconds`**: Adjust the amount of time skipped backward (default: 15s).
*   **`overflowModalColor`**: Color of the bottom modal sheet used for overflow menu items.
*   **`overflowModalTextColor`**: Color of text in bottom modal sheet used for overflow menu items.
*   **`sigmaX`, `sigmaY`**: (iOS only) The quality of the Gaussian Blur applied to the background.

## Dynamic Configuration Updates

You can update the controls configuration at runtime using the `setPlayerControlsConfiguration` method on the `BetterPlayerController`:

```dart
_betterPlayerController.setPlayerControlsConfiguration(
  PlayerControlsConfiguration(
      overflowModalColor: Colors.amberAccent,
  ),
);
```
