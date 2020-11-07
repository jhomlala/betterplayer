import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_configuration.dart';
import 'package:better_player/src/configuration/better_player_event.dart';
import 'package:better_player/src/configuration/better_player_event_type.dart';
import 'package:better_player/src/configuration/better_player_translations.dart';
import 'package:better_player/src/core/better_player_controller_provider.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:better_player/src/hls/better_player_hls_utils.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BetterPlayerController extends ChangeNotifier {
  static const _durationParameter = "duration";
  static const _progressParameter = "progress";
  static const _volumeParameter = "volume";
  static const _speedParameter = "speed";
  static const _hlsExtension = "m3u8";

  final BetterPlayerConfiguration betterPlayerConfiguration;
  final BetterPlayerPlaylistConfiguration betterPlayerPlaylistConfiguration;

  VideoPlayerController videoPlayerController;

  bool get autoPlay => betterPlayerConfiguration.autoPlay;

  Duration get startAt => betterPlayerConfiguration.startAt;

  bool get looping => betterPlayerConfiguration.looping;

  Widget Function(BuildContext context, String errorMessage) get errorBuilder =>
      betterPlayerConfiguration.errorBuilder;

  double get aspectRatio => betterPlayerConfiguration.aspectRatio;

  Widget get placeholder => betterPlayerConfiguration.placeholder;

  Widget get overlay => betterPlayerConfiguration.overlay;

  bool get fullScreenByDefault => betterPlayerConfiguration.fullScreenByDefault;

  bool get allowedScreenSleep => betterPlayerConfiguration.allowedScreenSleep;

  List<SystemUiOverlay> get systemOverlaysAfterFullScreen =>
      betterPlayerConfiguration.systemOverlaysAfterFullScreen;

  List<DeviceOrientation> get deviceOrientationsAfterFullScreen =>
      betterPlayerConfiguration.deviceOrientationsAfterFullScreen;

  /// Defines a event listener where video player events will be send
  Function(BetterPlayerEvent) get eventListener =>
      betterPlayerConfiguration.eventListener;

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  int _lastPositionSelection = 0;

  final List<Function> _eventListeners = List();

  BetterPlayerDataSource _betterPlayerDataSource;

  BetterPlayerDataSource get betterPlayerDataSource => _betterPlayerDataSource;

  List<BetterPlayerSubtitlesSource> _betterPlayerSubtitlesSourceList = List();

  List<BetterPlayerSubtitlesSource> get betterPlayerSubtitlesSourceList =>
      _betterPlayerSubtitlesSourceList;
  BetterPlayerSubtitlesSource _betterPlayerSubtitlesSource;

  BetterPlayerSubtitlesSource get betterPlayerSubtitlesSource =>
      _betterPlayerSubtitlesSource;

  List<BetterPlayerSubtitle> subtitlesLines = List();

  List<BetterPlayerHlsTrack> _betterPlayerTracks = List();

  List<BetterPlayerHlsTrack> get betterPlayerTracks => _betterPlayerTracks;

  BetterPlayerHlsTrack _betterPlayerTrack;

  BetterPlayerHlsTrack get betterPlayerTrack => _betterPlayerTrack;

  Timer _nextVideoTimer;

  int _nextVideoTime;
  StreamController<int> nextVideoTimeStreamController =
      StreamController.broadcast();

  bool _disposed = false;

  bool _wasPlayingBeforePause = false;

  ///Internal flag used to cancel dismiss of the full screen. Used when user
  ///switches quality (track or resolution) of the video. You should ignore it.
  bool cancelFullScreenDismiss = true;

  BetterPlayerTranslations translations = BetterPlayerTranslations();

  BetterPlayerController(
    this.betterPlayerConfiguration, {
    this.betterPlayerPlaylistConfiguration,
    BetterPlayerDataSource betterPlayerDataSource,
  }) : assert(betterPlayerConfiguration != null,
            "BetterPlayerConfiguration can't be null") {
    _eventListeners.add(eventListener);
    if (betterPlayerDataSource != null) {
      setupDataSource(betterPlayerDataSource);
    }
  }

  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>();

    return betterPLayerControllerProvider.controller;
  }

  Future setupDataSource(BetterPlayerDataSource betterPlayerDataSource) async {
    assert(
        betterPlayerDataSource != null, "BetterPlayerDataSource can't be null");

    _betterPlayerDataSource = betterPlayerDataSource;

    ///Build videoPlayerController if null
    if (videoPlayerController == null) {
      videoPlayerController = VideoPlayerController();
      videoPlayerController.addListener(_onVideoPlayerChanged);
    }

    ///Clear hls tracks
    betterPlayerTracks.clear();

    ///Setup subtitles
    List<BetterPlayerSubtitlesSource> betterPlayerSubtitlesSourceList =
        betterPlayerDataSource.subtitles;
    if (betterPlayerSubtitlesSourceList != null) {
      _betterPlayerSubtitlesSourceList.addAll(betterPlayerDataSource.subtitles);
    }

    /// Load hls tracks
    if (betterPlayerDataSource.url.contains(_hlsExtension)) {
      _betterPlayerTracks =
          await BetterPlayerHlsUtils.parseTracks(betterPlayerDataSource.url);
    }

    /// Load hls subtitles
    if (betterPlayerDataSource.useHlsSubtitles &&
        betterPlayerDataSource.url.contains(_hlsExtension)) {
      var hlsSubtitles =
          await BetterPlayerHlsUtils.parseSubtitles(betterPlayerDataSource.url);
      hlsSubtitles?.forEach((hlsSubtitle) {
        _betterPlayerSubtitlesSourceList.add(
          BetterPlayerSubtitlesSource(
              type: BetterPlayerSubtitlesSourceType.NETWORK,
              name: hlsSubtitle.name,
              urls: hlsSubtitle.realUrls),
        );
      });
    }

    _betterPlayerSubtitlesSourceList.add(BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.NONE));

    ///Process data source
    await _setupDataSource(betterPlayerDataSource);

    ///Setup subtitles (none is default)
    setupSubtitleSource(_betterPlayerSubtitlesSourceList.last);
  }

  ///Setup subtitles to be displayed from given subtitle source
  void setupSubtitleSource(BetterPlayerSubtitlesSource subtitlesSource) async {
    assert(subtitlesSource != null, "SubtitlesSource can't be null");
    _betterPlayerSubtitlesSource = subtitlesSource;
    subtitlesLines.clear();
    if (subtitlesSource.type != BetterPlayerSubtitlesSourceType.NONE) {
      var subtitlesParsed =
          await BetterPlayerSubtitlesFactory.parseSubtitles(subtitlesSource);
      subtitlesLines.addAll(subtitlesParsed);
    }

    _postEvent(BetterPlayerEvent(BetterPlayerEventType.CHANGED_SUBTITLES));
    if (!_disposed) {
      cancelFullScreenDismiss = true;
      notifyListeners();
    }
  }

  Future _setupDataSource(BetterPlayerDataSource betterPlayerDataSource) async {
    assert(
        betterPlayerDataSource != null, "BetterPlayerDataSource can't be null");
    switch (betterPlayerDataSource.type) {
      case BetterPlayerDataSourceType.NETWORK:
        await videoPlayerController.setNetworkDataSource(
          betterPlayerDataSource.url,
          headers: betterPlayerDataSource.headers,
          useCache:
              _betterPlayerDataSource.cacheConfiguration?.useCache ?? false,
          maxCacheSize:
              _betterPlayerDataSource.cacheConfiguration?.maxCacheSize ?? 0,
          maxCacheFileSize:
              _betterPlayerDataSource.cacheConfiguration?.maxCacheFileSize ?? 0,
        );

        break;
      case BetterPlayerDataSourceType.FILE:
        await videoPlayerController
            .setFileDataSource(File(betterPlayerDataSource.url));
        break;
      default:
        throw UnimplementedError(
            "${betterPlayerDataSource.type} is not implemented");
    }
    await _initialize();
  }

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await play();
    } else {
      if (fullScreenByDefault) {
        videoPlayerController.addListener(_fullScreenListener);
      }
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
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
    _postEvent(_isFullScreen
        ? BetterPlayerEvent(BetterPlayerEventType.OPEN_FULLSCREEN)
        : BetterPlayerEvent(BetterPlayerEventType.HIDE_FULLSCREEN));
    notifyListeners();
  }

  Future<void> play() async {
    await videoPlayerController.play();
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.PLAY));
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
        parameters: {_durationParameter: moment}));
    if (moment > videoPlayerController.value.duration) {
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.FINISHED));
    } else {
      cancelNextVideoTimer();
    }
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.SET_VOLUME,
        parameters: {_volumeParameter: volume}));
  }

  Future<void> setSpeed(double speed) async {
    if (speed < 0 || speed > 2) {
      throw ArgumentError("Speed must be between 0 and 2");
    }
    await videoPlayerController.setSpeed(speed);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.SET_SPEED,
        parameters: {_speedParameter: speed}));
  }

  Future<bool> isPlaying() async {
    return videoPlayerController.value.isPlaying;
  }

  bool isBuffering() {
    return videoPlayerController.value.isBuffering;
  }

  void toggleControlsVisibility(bool isVisible) {
    _postEvent(isVisible
        ? BetterPlayerEvent(BetterPlayerEventType.CONTROLS_VISIBLE)
        : BetterPlayerEvent(BetterPlayerEventType.CONTROLS_HIDDEN));
  }

  void _postEvent(BetterPlayerEvent betterPlayerEvent) {
    for (Function eventListener in _eventListeners) {
      if (eventListener != null) {
        eventListener(betterPlayerEvent);
      }
    }
  }

  void _onVideoPlayerChanged() async {
    var currentVideoPlayerValue = videoPlayerController.value;
    if (currentVideoPlayerValue.hasError) {
      _postEvent(
        BetterPlayerEvent(
          BetterPlayerEventType.EXCEPTION,
          parameters: {"exception": currentVideoPlayerValue.errorDescription},
        ),
      );
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPositionSelection > 500) {
      _lastPositionSelection = now;
      Duration currentPositionShifted = Duration(
          milliseconds: currentVideoPlayerValue.position.inMilliseconds + 500);
      if (currentPositionShifted == null ||
          currentVideoPlayerValue.duration == null) {
        return;
      }

      if (currentPositionShifted > currentVideoPlayerValue.duration) {
        _postEvent(
            BetterPlayerEvent(BetterPlayerEventType.FINISHED, parameters: {
          _progressParameter: currentVideoPlayerValue.position,
          _durationParameter: currentVideoPlayerValue.duration
        }));
      } else {
        _postEvent(
            BetterPlayerEvent(BetterPlayerEventType.PROGRESS, parameters: {
          _progressParameter: currentVideoPlayerValue.position,
          _durationParameter: currentVideoPlayerValue.duration
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

  void startNextVideoTimer() {
    if (_nextVideoTimer == null) {
      _nextVideoTime =
          betterPlayerPlaylistConfiguration.nextVideoDelay.inSeconds;
      nextVideoTimeStreamController.add(_nextVideoTime);
      _nextVideoTimer =
          Timer.periodic(Duration(milliseconds: 1000), (_timer) async {
        if (_nextVideoTime == 1) {
          _timer.cancel();
          _nextVideoTimer = null;
        }
        _nextVideoTime -= 1;
        nextVideoTimeStreamController.add(_nextVideoTime);
      });
    }
  }

  void cancelNextVideoTimer() {
    _nextVideoTime = null;
    nextVideoTimeStreamController.add(_nextVideoTime);
    _nextVideoTimer?.cancel();
    _nextVideoTimer = null;
  }

  void playNextVideo() {
    _nextVideoTime = 0;
    nextVideoTimeStreamController.add(_nextVideoTime);
    cancelNextVideoTimer();
  }

  ///Setup track parameters for currently played video
  void setTrack(BetterPlayerHlsTrack track) {
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.CHANGED_TRACK));

    ///Default element clicked:
    if (track.width == 0 && track.height == 0 && track.bitrate == 0) {
      return;
    }

    videoPlayerController.setTrackParameters(
        track.width, track.height, track.bitrate);
    _betterPlayerTrack = track;
  }

  void onPlayerVisibilityChanged(double visibilityFraction) async {
    if (_disposed) {
      return;
    }
    _postEvent(
        BetterPlayerEvent(BetterPlayerEventType.CHANGED_PLAYER_VISIBILITY));
    if (betterPlayerConfiguration.playerVisibilityChangedBehavior != null) {
      betterPlayerConfiguration
          .playerVisibilityChangedBehavior(visibilityFraction);
    } else {
      if (visibilityFraction == 0) {
        _wasPlayingBeforePause = await isPlaying();
        pause();
      } else {
        if (_wasPlayingBeforePause && !(await isPlaying())) {
          play();
        }
      }
    }
  }

  ///Set different resolution (quality) for video
  void setResolution(String url) async {
    assert(url != null, "Url can't be null");
    var position = await videoPlayerController.position;
    var wasPlayingBeforeChange = await isPlaying();
    cancelFullScreenDismiss = true;
    videoPlayerController.pause();
    await setupDataSource(betterPlayerDataSource.copyWith(url: url));
    videoPlayerController.seekTo(position);
    if (wasPlayingBeforeChange) {
      videoPlayerController.play();
    }
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.CHANGED_RESOLUTION));
  }

  ///Setup translations for given locale. In normal use cases it shouldn't be
  ///called manually.
  void setupTranslations(Locale locale) {
    if (locale != null) {
      String languageCode = locale.languageCode;
      translations = betterPlayerConfiguration.translations?.firstWhere(
              (translations) => translations.languageCode == languageCode,
              orElse: () => null) ??
          _getDefaultTranslations(locale);
    } else {
      print("Locale is null. Couldn't setup translations.");
    }
  }

  ///Setup default translations for selected user locale. These translations
  ///are pre-build in.
  BetterPlayerTranslations _getDefaultTranslations(Locale locale) {
    if (locale != null) {
      String languageCode = locale.languageCode;
      switch (languageCode) {
        case "pl":
          return BetterPlayerTranslations.polish();
        case "zh":
          return BetterPlayerTranslations.chinese();
        case "hi":
          return BetterPlayerTranslations.hindi();
        default:
          return BetterPlayerTranslations();
      }
    }
    return BetterPlayerTranslations();
  }

  @override
  void dispose() {
    if (!_disposed) {
      _eventListeners.clear();
      videoPlayerController?.removeListener(_fullScreenListener);
      videoPlayerController?.removeListener(_onVideoPlayerChanged);
      videoPlayerController?.dispose();
      _nextVideoTimer?.cancel();
      nextVideoTimeStreamController.close();
      _disposed = true;
      super.dispose();
    }
  }
}
