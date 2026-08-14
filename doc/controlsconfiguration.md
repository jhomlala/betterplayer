## Controls configuration
Controls (UI) of the player can be customized with `BetterPlayerControlsConfiguration` class. You should pass this configuration to `BetterPlayerConfiguration` instance.

```dart
var betterPlayerConfiguration = BetterPlayerConfiguration(
    controlsConfiguration: BetterPlayerControlsConfiguration(
        textColor: Colors.black,
        iconsColor: Colors.black,
    ),
);
```


```dart
///Color of the control bars
final Color controlBarColor;

///Color of texts
final Color textColor;

///Color of icons
final Color iconsColor;

///Icon of play
final IconData playIcon;

///Icon of pause
final IconData pauseIcon;

///Icon of mute
final IconData muteIcon;

///Icon of unmute
final IconData unMuteIcon;

///Icon of fullscreen mode enable
final IconData fullscreenEnableIcon;

///Icon of fullscreen mode disable
final IconData fullscreenDisableIcon;

///Cupertino only icon, icon of skip
final IconData skipBackIcon;

///Cupertino only icon, icon of forward
final IconData skipForwardIcon;

///Flag used to enable/disable fullscreen
final bool enableFullscreen;

///Flag used to enable/disable mute
final bool enableMute;

///Flag used to enable/disable progress texts
final bool enableProgressText;

///Flag used to enable/disable progress bar
final bool enableProgressBar;

///Flag used to enable/disable progress bar drag
final bool enableProgressBarDrag;

///Flag used to enable/disable play-pause
final bool enablePlayPause;

///Flag used to enable skip forward and skip back
final bool enableSkips;

///Progress bar played color
final Color progressBarPlayedColor;

///Progress bar circle color
final Color progressBarHandleColor;

///Progress bar buffered video color
final Color progressBarBufferedColor;

///Progress bar background color
final Color progressBarBackgroundColor;

///Time to hide controls
final Duration controlsHideTime;

///Parameter used to build custom controls
final Widget Function(BetterPlayerController controller)
       customControlsBuilder;

///Parameter used to change theme of the player
final BetterPlayerTheme playerTheme;

///Flag used to show/hide controls
final bool showControls;

///Flag used to show controls on init
final bool showControlsOnInitialize;

///Control bar height
final double controlBarHeight;

///Live text color;
final Color liveTextColor;

///Flag used to show/hide overflow menu which contains playback, subtitles,
///qualities options.
final bool enableOverflowMenu;

///Flag used to show/hide playback speed
final bool enablePlaybackSpeed;

///Flag used to show/hide subtitles
final bool enableSubtitles;

///Flag used to show/hide qualities
final bool enableQualities;

///Flag used to show/hide PiP mode
final bool enablePip;

///Flag used to enable/disable retry feature
final bool enableRetry;

///Flag used to show/hide audio tracks
final bool enableAudioTracks;

///Custom items of overflow menu
final List<BetterPlayerOverflowMenuItem> overflowMenuCustomItems;

///Icon of the overflow menu
final IconData overflowMenuIcon;

///Icon of the playback speed menu item from overflow menu
final IconData playbackSpeedIcon;

///Icon of the subtitles menu item from overflow menu
final IconData subtitlesIcon;

///Icon of the qualities menu item from overflow menu
final IconData qualitiesIcon;

///Icon of the audios menu item from overflow menu
final IconData audioTracksIcon;

///Color of overflow menu icons
final Color overflowMenuIconsColor;

///Time which will be used once user uses forward
final int forwardSkipTimeInMilliseconds;

///Time which will be used once user uses backward
final int backwardSkipTimeInMilliseconds;

///Color of default loading indicator
final Color loadingColor;

///Widget which can be used instead of default progress
final Widget loadingWidget;

///Color of the background, when no frame is displayed.
final Color backgroundColor;

///Quality of Gaussian Blur for x (iOS only).
final double sigmaX;

///Quality of Gaussian Blur for y (iOS only).
final double sigmaY;
```

You can change controls configuration in runtime with `setBetterPlayerControlsConfiguration` method of `BetterPlayerController`.

```dart
 _betterPlayerController.setBetterPlayerControlsConfiguration(
                  BetterPlayerControlsConfiguration(
                      overflowModalColor: Colors.amberAccent),
                );
```