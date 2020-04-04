import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_controls_configuration.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'better_player_event.dart';

class BetterPlayerSettings {
  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

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

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final BetterPlayerProgressColors cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final BetterPlayerProgressColors materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// A widget which is placed between the video and the controls
  final Widget overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final BetterPlayerRoutePageBuilder routePageBuilder;

  /// Defines a event listener where video player events will be send
  final Function(BetterPlayerEvent) eventListener;

  final BetterPlayerSubtitlesConfiguration subtitlesConfiguration;

  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerSettings(
      {this.aspectRatio,
      this.autoInitialize = false,
      this.autoPlay = false,
      this.startAt,
      this.looping = false,
      this.fullScreenByDefault = false,
      this.cupertinoProgressColors,
      this.materialProgressColors,
      this.placeholder,
      this.overlay,
      this.showControlsOnInitialize = true,
      this.errorBuilder,
      this.allowedScreenSleep = true,
      this.isLive = false,
      this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
      this.deviceOrientationsAfterFullScreen = const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      this.routePageBuilder,
      this.eventListener,
      this.subtitlesConfiguration = const BetterPlayerSubtitlesConfiguration(),
      this.controlsConfiguration = const BetterPlayerControlsConfiguration()});
}
