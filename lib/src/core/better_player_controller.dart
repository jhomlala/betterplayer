import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_configuration.dart';
import 'package:better_player/src/configuration/better_player_event.dart';
import 'package:better_player/src/configuration/better_player_event_type.dart';
import 'package:better_player/src/core/better_player_controller_provider.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class BetterPlayerController extends ChangeNotifier {
  BetterPlayerController(this.betterPlayerConfiguration,
      {this.betterPlayerPlaylistConfiguration, this.betterPlayerDataSource}) {
    _eventListeners.add(eventListener);
    if (betterPlayerDataSource != null) {
      _setup(betterPlayerDataSource);
    }
  }

  final BetterPlayerConfiguration betterPlayerConfiguration;
  final BetterPlayerPlaylistConfiguration betterPlayerPlaylistConfiguration;
  final BetterPlayerDataSource betterPlayerDataSource;

  /// The controller for the video you want to play
  VideoPlayerController videoPlayerController;

  /// Play the video as soon as it's displayed
  bool get autoPlay => betterPlayerConfiguration.autoPlay;

  /// Start video at a certain position
  Duration get startAt => betterPlayerConfiguration.startAt;

  /// Whether or not the video should loop
  bool get looping => betterPlayerConfiguration.looping;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  Widget Function(BuildContext context, String errorMessage) get errorBuilder =>
      null;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  double get aspectRatio => betterPlayerConfiguration.aspectRatio;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  Widget get placeholder => betterPlayerConfiguration.placeholder;

  /// A widget which is placed between the video and the controls
  Widget get overlay => betterPlayerConfiguration.overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  bool get fullScreenByDefault => betterPlayerConfiguration.fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  bool get allowedScreenSleep => betterPlayerConfiguration.allowedScreenSleep;

  /// Defines the system overlays visible after exiting fullscreen
  List<SystemUiOverlay> get systemOverlaysAfterFullScreen =>
      betterPlayerConfiguration.systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  List<DeviceOrientation> get deviceOrientationsAfterFullScreen =>
      betterPlayerConfiguration.deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  BetterPlayerRoutePageBuilder routePageBuilder;

  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>();

    return betterPLayerControllerProvider.controller;
  }

  /// Defines a event listener where video player events will be send
  Function(BetterPlayerEvent) get eventListener =>
      betterPlayerConfiguration.eventListener;

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  int _lastPositionSelection = 0;

  final List<Function> _eventListeners = List();

  bool isDisposing = false;

  BetterPlayerDataSource _betterPlayerDataSource;

  List<BetterPlayerSubtitle> subtitles = List();

  Future _setup(BetterPlayerDataSource dataSource) async {
    _betterPlayerDataSource = dataSource;
    if (dataSource.subtitles != null) {
      subtitles.clear();
      BetterPlayerSubtitlesFactory.parseSubtitles(dataSource.subtitles)
          .then((data) {
        subtitles.addAll(data);
      });
    }
    videoPlayerController =
        _createVideoPlayerController(betterPlayerDataSource);
    await _initialize();
  }

  VideoPlayerController _createVideoPlayerController(
      BetterPlayerDataSource betterPlayerDataSource) {
    switch (betterPlayerDataSource.type) {
      case BetterPlayerDataSourceType.NETWORK:
        return VideoPlayerController.network(betterPlayerDataSource.url);
      case BetterPlayerDataSourceType.FILE:
        return VideoPlayerController.file(File(betterPlayerDataSource.url));
      default:
        throw UnimplementedError(
            "${betterPlayerDataSource.type} is not implemented");
    }
  }

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if (!videoPlayerController.value.initialized) {
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
    print("Toggle full screen");
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
    if (now - _lastPositionSelection > 500) {
      _lastPositionSelection = now;
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

  void addEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.add(eventListener);
  }

  bool isLiveStream() {
    return _betterPlayerDataSource?.liveStream;
  }

  bool isVideoInitialized() {
    return videoPlayerController.value.initialized;
  }

  @override
  void dispose() {
    _eventListeners.clear();
    videoPlayerController?.removeListener(_fullScreenListener);
    videoPlayerController?.removeListener(_onVideoPlayerChanged);
    videoPlayerController?.dispose();
    super.dispose();
  }
}
