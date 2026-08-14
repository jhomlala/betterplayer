## General configuration
To setup general options of Better Player you need to create `BetterPlayerConfiguration` instance. You will use this object during creation of `BetterPlayerController`.

```dart
var betterPlayerConfiguration = BetterPlayerConfiguration(
    autoPlay: true,
    looping: true,
    fullScreenByDefault: true,
);
```

Possible configuration options which you can find in `BetterPlayerConfiguration`:
```dart
/// Play the video as soon as it's displayed
final bool autoPlay;

/// Start video at a certain position
final Duration startAt;

/// Whether or not the video should loop
final bool looping;

/// Weather or not to show the controls when initializing the widget.
final bool showControlsOnInitialize;

/// When the video playback runs  into an error, you can build a custom
/// error message.
final Widget Function(BuildContext context, String errorMessage) errorBuilder;

/// The Aspect Ratio of the Video. Important to get the correct size of the
/// video!
///
/// Will fallback to fitting within the space allowed.
final double aspectRatio;

/// The placeholder is displayed underneath the Video before it is initialized
/// or played.
final Widget placeholder;

/// Should the placeholder be shown until play is pressed
final bool showPlaceholderUntilPlay;

/// Placeholder position of player stack. If false, then placeholder will be
/// displayed on the bottom, so user need to hide it manually. Default is
/// true.
final bool placeholderOnTop;

/// A widget which is placed between the video and the controls
final Widget overlay;

/// Defines if the player will start in fullscreen when play is pressed
final bool fullScreenByDefault;

/// Defines if the player will sleep in fullscreen or not
final bool allowedScreenSleep;

/// Defines aspect ratio which will be used in fullscreen
final double fullScreenAspectRatio;

/// Defines the set of allowed device orientations on entering fullscreen
final List<DeviceOrientation> deviceOrientationsOnFullScreen;

/// Defines the system overlays visible after exiting fullscreen
final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

/// Defines the set of allowed device orientations after exiting fullscreen
final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

/// Defines a custom RoutePageBuilder for the fullscreen
final BetterPlayerRoutePageBuilder routePageBuilder;

/// Defines a event listener where video player events will be send
final Function(BetterPlayerEvent) eventListener;

///Defines subtitles configuration
final BetterPlayerSubtitlesConfiguration subtitlesConfiguration;

///Defines controls configuration
final BetterPlayerControlsConfiguration controlsConfiguration;

///Defines fit of the video, allows to fix video stretching, see possible
///values here: https://api.flutter.dev/flutter/painting/BoxFit-class.html
final BoxFit fit;

///Defines rotation of the video in degrees. Default value is 0. Can be 0, 90, 180, 270.
///Angle will rotate only video box, controls will be in the same place.
final double rotation;
    
///Defines function which will react on player visibility changed
final Function(double visibilityFraction) playerVisibilityChangedBehavior;

///Defines translations used in player. If null, then default english translations
///will be used.
final List<BetterPlayerTranslations> translations;

///Defines if player should auto detect full screen device orientation based
///on aspect ratio of the video. If aspect ratio of the video is < 1 then
///video will played in full screen in portrait mode. If aspect ratio is >= 1
///then video will be played horizontally. If this parameter is true, then
///[deviceOrientationsOnFullScreen] and [fullScreenAspectRatio] value will be
/// ignored.
final bool autoDetectFullscreenDeviceOrientation;

///Defines if player should auto detect full screen aspect ration of the video.
///If [deviceOrientationsOnFullScreen] is true this is done automaticaly also.
final bool autoDetectFullscreenAspectRatio;

///Defines flag which enables/disables lifecycle handling (pause on app closed,
///play on app resumed). Default value is true.
final bool handleLifecycle;

///Defines flag which enabled/disabled auto dispose on BetterPlayer dispose.
///Default value is true.
final bool autoDispose;

///Flag which causes to player expand to fill all remaining space. Set to false
///to use minimum constraints
final bool expandToFill;

///Flag which causes to player use the root navigator to open new pages.
///Default value is false.
final bool useRootNavigator;
```