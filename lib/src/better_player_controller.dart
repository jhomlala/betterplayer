import 'package:better_player/better_player.dart';
import 'package:better_player/src/better_player_controller_provider.dart';
import 'package:better_player/src/better_player_progress_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// The ChewieController is used to configure and drive the Chewie Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the ChewieController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
class BetterPlayerController extends ChangeNotifier {
  BetterPlayerController(
      {this.videoPlayerController,
      this.aspectRatio,
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
      this.showControls = true,
      this.customControls,
      this.errorBuilder,
      this.allowedScreenSleep = true,
      this.isLive = false,
      this.allowFullScreen = true,
      this.allowMuting = true,
      this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
      this.deviceOrientationsAfterFullScreen = const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      this.routePageBuilder})
      : assert(videoPlayerController != null,
            'You must provide a controller to play a video') {
    _initialize();
  }

  factory BetterPlayerController.network(String videoUrl,
      {double aspectRatio,
      bool autoInitialize = false,
      bool autoPlay = false,
      Duration startAt,
      bool looping = false,
      bool fullScreenByDefault = false,
      BetterPlayerProgressColors cupertinoProgressColors,
      BetterPlayerProgressColors materialProgressColors,
      Widget placeholder,
      Widget overlay,
      bool showControlsOnInitialize = true,
      bool showControls = true,
      Widget customControls,
      Function(BuildContext context, String errorMessage) errorBuilder,
      bool allowedScreenSleep = false,
      bool isLive = false,
      bool allowFullScreen = true,
      bool allowMuting = true,
      List<SystemUiOverlay> systemOverlaysAfterFullScreen =
          SystemUiOverlay.values,
      List<DeviceOrientation> deviceOrientationsAfterFullScreen,
      BetterPlayerRoutePageBuilder routePageBuilder}) {
    VideoPlayerController videoPlayerController =
        VideoPlayerController.network(videoUrl);
    return BetterPlayerController(
        videoPlayerController: videoPlayerController,
        aspectRatio: aspectRatio,
        autoInitialize: autoInitialize,
        autoPlay: autoPlay,
        startAt: startAt,
        looping: looping,
        fullScreenByDefault: fullScreenByDefault,
        cupertinoProgressColors: cupertinoProgressColors,
        materialProgressColors: materialProgressColors,
        placeholder: placeholder,
        overlay: overlay,
        showControlsOnInitialize: showControlsOnInitialize,
        showControls: showControls,
        errorBuilder: errorBuilder,
        allowedScreenSleep: allowedScreenSleep,
        isLive: isLive,
        allowFullScreen: allowFullScreen,
        allowMuting: allowMuting,
        systemOverlaysAfterFullScreen: systemOverlaysAfterFullScreen,
        routePageBuilder: routePageBuilder);
  }

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

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

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget customControls;

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

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final BetterPlayerRoutePageBuilder routePageBuilder;

  static BetterPlayerController of(BuildContext context) {
    final chewieControllerProvider =
        context.inheritFromWidgetOfExactType(BetterPlayerControllerProvider)
            as BetterPlayerControllerProvider;

    return chewieControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.initialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  void _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }
}
