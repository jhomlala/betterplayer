import 'package:better_player/better_player.dart';
import 'package:better_player/src/better_player_controller_provider.dart';
import 'package:better_player/src/better_player_data_source.dart';
import 'package:better_player/src/better_player_event.dart';
import 'package:better_player/src/better_player_event_type.dart';
import 'package:better_player/src/better_player_progress_colors.dart';
import 'package:better_player/src/better_player_settings.dart';
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
  BetterPlayerController(this.betterPlayerSettings,
      {this.betterPlayerPlaylistSettings}) {
    _eventListeners.add(eventListener);
    //_initialize();
  }

  factory BetterPlayerController.network(
      String videoUrl, BetterPlayerSettings betterPlayerSettings) {
    return BetterPlayerController(betterPlayerSettings);
  }

  final BetterPlayerSettings betterPlayerSettings;
  final BetterPlayerPlaylistSettings betterPlayerPlaylistSettings;

  /// The controller for the video you want to play
  VideoPlayerController videoPlayerController;

  /// Initialize the Video on Startup. This will prep the video for playback.
  bool get autoInitialize => betterPlayerSettings.autoInitialize;

  /// Play the video as soon as it's displayed
  bool get autoPlay => betterPlayerSettings.autoPlay;

  /// Start video at a certain position
  Duration get startAt => betterPlayerSettings.startAt;

  /// Whether or not the video should loop
  bool get looping => betterPlayerSettings.looping;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  Widget Function(BuildContext context, String errorMessage) get errorBuilder =>
      null;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  double get aspectRatio => betterPlayerSettings.aspectRatio;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  BetterPlayerProgressColors get cupertinoProgressColors =>
      betterPlayerSettings.cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  BetterPlayerProgressColors get materialProgressColors =>
      betterPlayerSettings.materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  Widget get placeholder => betterPlayerSettings.placeholder;

  /// A widget which is placed between the video and the controls
  Widget get overlay => betterPlayerSettings.overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  bool get fullScreenByDefault => betterPlayerSettings.fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  bool get allowedScreenSleep => betterPlayerSettings.allowedScreenSleep;

  /// Defines if the controls should be for live stream video
  bool get isLive => betterPlayerSettings.isLive;

  /// Defines the system overlays visible after exiting fullscreen
  List<SystemUiOverlay> get systemOverlaysAfterFullScreen =>
      betterPlayerSettings.systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  List<DeviceOrientation> get deviceOrientationsAfterFullScreen =>
      betterPlayerSettings.deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  BetterPlayerRoutePageBuilder routePageBuilder;

  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>();

    return betterPLayerControllerProvider.controller;
  }

  /// Defines a event listener where video player events will be send
  Function(BetterPlayerEvent) get eventListener =>
      betterPlayerSettings.eventListener;

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  int lastPositionSelection = 0;

  final List<Function> _eventListeners = List();

  bool isDisposing = false;

  Future setup(BetterPlayerDataSource dataSource) async {
    videoPlayerController = VideoPlayerController.network(dataSource.url);
    return await _initialize();
  }

  Future _initialize() async {
    print("Initlize!!");
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.initialized) {
      try {
        await videoPlayerController.initialize();
      } catch (exception, stackTrace) {
        print(exception);
        print(stackTrace);
      }
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }

    ///General purpose listener
    videoPlayerController.addListener(_onVideoPlayerChanged);
  }

  void _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    if (!isDisposing) {
      _isFullScreen = true;
      notifyListeners();
    }
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    _postEvent(_isFullScreen
        ? BetterPlayerEvent(BetterPlayerEventType.OPEN_FULLSCREEN)
        : BetterPlayerEvent(BetterPlayerEventType.HIDE_FULLSCREEN));
    notifyListeners();
  }

  Future<void> play() async {
    if (!isDisposing) {
      await videoPlayerController.play();
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.PLAY));
    }
  }

  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.PAUSE));
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.SEEK_TO,
        parameters: {"duration": moment}));
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.SET_VOLUME,
        parameters: {"volume": volume}));
  }

  Future<bool> isPlaying() async {
    return videoPlayerController.value.isPlaying;
  }

  bool isBuffering() {
    return videoPlayerController.value.isBuffering;
  }

  void _postEvent(BetterPlayerEvent betterPlayerEvent) {
    for (Function eventListener in _eventListeners) {
      if (eventListener != null) {
        eventListener(betterPlayerEvent);
      }
    }
  }

  void _onVideoPlayerChanged() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastPositionSelection > 500) {
      lastPositionSelection = now;
      var currentVideoPlayerValue = videoPlayerController.value;
      Duration currentPositionShifted = Duration(
          milliseconds: currentVideoPlayerValue.position.inMilliseconds + 500);
      if (currentPositionShifted > currentVideoPlayerValue.duration) {
        _postEvent(
            BetterPlayerEvent(BetterPlayerEventType.FINISHED, parameters: {
          "progress": currentVideoPlayerValue.position,
          "duration": currentVideoPlayerValue.duration
        }));
      } else {
        _postEvent(
            BetterPlayerEvent(BetterPlayerEventType.PROGRESS, parameters: {
          "progress": currentVideoPlayerValue.position,
          "duration": currentVideoPlayerValue.duration
        }));
      }
    }
  }

  void _handleInitializationException(Exception exception) {
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.EXCEPTION,
        parameters: {"exception": exception}));
  }

  void addEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.add(eventListener);
  }
}
