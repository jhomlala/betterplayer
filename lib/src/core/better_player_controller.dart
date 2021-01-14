// Dart imports:
import 'dart:async';
import 'dart:io';

// Project imports:
import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_configuration.dart';
import 'package:better_player/src/configuration/better_player_event.dart';
import 'package:better_player/src/configuration/better_player_event_type.dart';
import 'package:better_player/src/configuration/better_player_translations.dart';
import 'package:better_player/src/core/better_player_controller_provider.dart';

// Flutter imports:
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:better_player/src/hls/better_player_hls_utils.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:path_provider/path_provider.dart';

class BetterPlayerController extends ChangeNotifier {
  static const _durationParameter = "duration";
  static const _progressParameter = "progress";
  static const _volumeParameter = "volume";
  static const _speedParameter = "speed";
  static const _hlsExtension = "m3u8";

  final BetterPlayerConfiguration betterPlayerConfiguration;
  final BetterPlayerPlaylistConfiguration betterPlayerPlaylistConfiguration;
  final List<Function> _eventListeners = [];
  final List<BetterPlayerSubtitlesSource> _betterPlayerSubtitlesSourceList = [];

  ///List of files to delete once player disposes.
  final List<File> _tempFiles = [];
  final StreamController<bool> _controlsVisibilityStreamController =
      StreamController.broadcast();

  VideoPlayerController videoPlayerController;

  bool get autoPlay => betterPlayerConfiguration.autoPlay;

  Widget Function(BuildContext context, String errorMessage) get errorBuilder =>
      betterPlayerConfiguration.errorBuilder;

  /// Defines a event listener where video player events will be send
  Function(BetterPlayerEvent) get eventListener =>
      betterPlayerConfiguration.eventListener;

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  int _lastPositionSelection = 0;

  BetterPlayerDataSource _betterPlayerDataSource;

  BetterPlayerDataSource get betterPlayerDataSource => _betterPlayerDataSource;

  List<BetterPlayerSubtitlesSource> get betterPlayerSubtitlesSourceList =>
      _betterPlayerSubtitlesSourceList;
  BetterPlayerSubtitlesSource _betterPlayerSubtitlesSource;

  BetterPlayerSubtitlesSource get betterPlayerSubtitlesSource =>
      _betterPlayerSubtitlesSource;

  List<BetterPlayerSubtitle> subtitlesLines = [];

  List<BetterPlayerHlsTrack> _betterPlayerTracks = [];

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

  ///Currently used translations
  BetterPlayerTranslations translations = BetterPlayerTranslations();

  ///Has current data source started
  bool _hasCurrentDataSourceStarted = false;

  ///Has current data source initialized
  bool _hasCurrentDataSourceInitialized = false;

  ///Stream which sends flag whenever visibility of controls changes
  Stream<bool> get controlsVisibilityStream =>
      _controlsVisibilityStreamController.stream;

  ///Current app lifecycle state.
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  ///Flag which determines if controls (UI interface) is shown. When false,
  ///UI won't be shown (show only player surface).
  bool _controlsEnabled = true;

  ///Flag which determines if controls (UI interface) is shown. When false,
  ///UI won't be shown (show only player surface).
  bool get controlsEnabled => _controlsEnabled;

  ///Overridden aspect ratio which will be used instead of aspect ratio passed
  ///in configuration.
  double _overriddenAspectRatio;

  ///Was Picture in Picture opened.
  bool _wasInPipMode = false;

  ///Was player in fullscreen before Picture in Picture opened.
  bool _wasInFullScreenBeforePiP = false;

  ///Was controls enabled before Picture in Picture opened.
  bool _wasControlsEnabledBeforePiP = false;

  ///GlobalKey of the BetterPlayer widget
  GlobalKey _betterPlayerGlobalKey;

  ///Getter of the GlobalKey
  GlobalKey get betterPlayerGlobalKey => _betterPlayerGlobalKey;

  ///StreamSubscription for VideoEvent listener
  StreamSubscription<VideoEvent> _videoEventStreamSubscription;

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
    _hasCurrentDataSourceStarted = false;
    _hasCurrentDataSourceInitialized = false;
    _betterPlayerDataSource = betterPlayerDataSource;

    ///Build videoPlayerController if null
    if (videoPlayerController == null) {
      videoPlayerController = VideoPlayerController();
      videoPlayerController.addListener(_onVideoPlayerChanged);
    }

    ///Clear hls tracks
    betterPlayerTracks.clear();

    ///Setup subtitles
    final List<BetterPlayerSubtitlesSource> betterPlayerSubtitlesSourceList =
        betterPlayerDataSource.subtitles;
    if (betterPlayerSubtitlesSourceList != null) {
      _betterPlayerSubtitlesSourceList.addAll(betterPlayerDataSource.subtitles);
    }

    /// Load hls tracks
    if (_betterPlayerDataSource?.useHlsTracks == true &&
        betterPlayerDataSource.url.contains(_hlsExtension)) {
      _betterPlayerTracks =
          await BetterPlayerHlsUtils.parseTracks(betterPlayerDataSource.url);
    }

    /// Load hls subtitles
    if (betterPlayerDataSource?.useHlsSubtitles == true &&
        betterPlayerDataSource.url.contains(_hlsExtension)) {
      final hlsSubtitles =
          await BetterPlayerHlsUtils.parseSubtitles(betterPlayerDataSource.url);
      hlsSubtitles?.forEach((hlsSubtitle) {
        _betterPlayerSubtitlesSourceList.add(
          BetterPlayerSubtitlesSource(
              type: BetterPlayerSubtitlesSourceType.network,
              name: hlsSubtitle.name,
              urls: hlsSubtitle.realUrls),
        );
      });
    }

    _betterPlayerSubtitlesSourceList.add(
      BetterPlayerSubtitlesSource(type: BetterPlayerSubtitlesSourceType.none),
    );

    ///Process data source
    await _setupDataSource(betterPlayerDataSource);

    final defaultSubtitle = _betterPlayerSubtitlesSourceList.firstWhere(
        (element) => element.selectedByDefault == true,
        orElse: () => null);

    ///Setup subtitles (none is default)
    setupSubtitleSource(
        defaultSubtitle ?? _betterPlayerSubtitlesSourceList.last);
  }

  ///Setup subtitles to be displayed from given subtitle source
  Future<void> setupSubtitleSource(
      BetterPlayerSubtitlesSource subtitlesSource) async {
    assert(subtitlesSource != null, "SubtitlesSource can't be null");
    _betterPlayerSubtitlesSource = subtitlesSource;
    subtitlesLines.clear();
    if (subtitlesSource.type != BetterPlayerSubtitlesSourceType.none) {
      final subtitlesParsed =
          await BetterPlayerSubtitlesFactory.parseSubtitles(subtitlesSource);
      subtitlesLines.addAll(subtitlesParsed);
    }

    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedSubtitles));
    if (!_disposed) {
      cancelFullScreenDismiss = true;
      notifyListeners();
    }
  }

  Future _setupDataSource(BetterPlayerDataSource betterPlayerDataSource) async {
    assert(
        betterPlayerDataSource != null, "BetterPlayerDataSource can't be null");
    switch (betterPlayerDataSource.type) {
      case BetterPlayerDataSourceType.network:
        await videoPlayerController.setNetworkDataSource(
          betterPlayerDataSource.url,
          headers: betterPlayerDataSource.headers,
          useCache:
              _betterPlayerDataSource.cacheConfiguration?.useCache ?? false,
          maxCacheSize:
              _betterPlayerDataSource.cacheConfiguration?.maxCacheSize ?? 0,
          maxCacheFileSize:
              _betterPlayerDataSource.cacheConfiguration?.maxCacheFileSize ?? 0,
          showNotification: _betterPlayerDataSource
              .notificationConfiguration?.showNotification,
          title: _betterPlayerDataSource?.notificationConfiguration?.title,
          author: _betterPlayerDataSource?.notificationConfiguration?.author,
          imageUrl:
              _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
          notificationChannelName: _betterPlayerDataSource
              ?.notificationConfiguration?.notificationChannelName,
          overriddenDuration: _betterPlayerDataSource.overriddenDuration,
        );

        break;
      case BetterPlayerDataSourceType.file:
        await videoPlayerController.setFileDataSource(
          File(betterPlayerDataSource.url),
          showNotification: _betterPlayerDataSource
              .notificationConfiguration?.showNotification,
          title: _betterPlayerDataSource?.notificationConfiguration?.title,
          author: _betterPlayerDataSource?.notificationConfiguration?.author,
          imageUrl:
              _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
          notificationChannelName: _betterPlayerDataSource
              ?.notificationConfiguration?.notificationChannelName,
          overriddenDuration: _betterPlayerDataSource.overriddenDuration,
        );
        break;
      case BetterPlayerDataSourceType.memory:
        final file = await _createFile(_betterPlayerDataSource.bytes);

        if (file != null) {
          await videoPlayerController.setFileDataSource(
            file,
            showNotification: _betterPlayerDataSource
                .notificationConfiguration?.showNotification,
            title: _betterPlayerDataSource?.notificationConfiguration?.title,
            author: _betterPlayerDataSource?.notificationConfiguration?.author,
            imageUrl:
                _betterPlayerDataSource?.notificationConfiguration?.imageUrl,
            notificationChannelName: _betterPlayerDataSource
                ?.notificationConfiguration?.notificationChannelName,
            overriddenDuration: _betterPlayerDataSource.overriddenDuration,
          );
          _tempFiles.add(file);
        } else {
          throw ArgumentError("Couldn't create file from memory.");
        }
        break;

      default:
        throw UnimplementedError(
            "${betterPlayerDataSource.type} is not implemented");
    }
    await _initialize();
  }

  Future<File> _createFile(List<int> bytes) async {
    final String dir = (await getTemporaryDirectory()).path;
    final File temp = File('$dir/better_player_${DateTime.now()}.temp');
    await temp.writeAsBytes(bytes);
    return temp;
  }

  Future _initialize() async {
    await videoPlayerController.setLooping(betterPlayerConfiguration.looping);
    _videoEventStreamSubscription = videoPlayerController
        .videoEventStreamController.stream
        .listen(_handleVideoEvent);
    final fullScreenByDefault = betterPlayerConfiguration.fullScreenByDefault;
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

    final startAt = betterPlayerConfiguration.startAt;
    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }
  }

  Future<void> _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.openFullscreen));
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.hideFullscreen));
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    _postEvent(_isFullScreen
        ? BetterPlayerEvent(BetterPlayerEventType.openFullscreen)
        : BetterPlayerEvent(BetterPlayerEventType.hideFullscreen));
    notifyListeners();
  }

  Future<void> play() async {
    if (_appLifecycleState == AppLifecycleState.resumed) {
      await videoPlayerController.play();
      _hasCurrentDataSourceStarted = true;
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
    }
  }

  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.pause));
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);

    _postEvent(BetterPlayerEvent(BetterPlayerEventType.seekTo,
        parameters: <String, dynamic>{_durationParameter: moment}));
    if (moment > videoPlayerController.value.duration) {
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.finished));
    } else {
      cancelNextVideoTimer();
    }
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.setVolume,
        parameters: <String, dynamic>{_volumeParameter: volume}));
  }

  Future<void> setSpeed(double speed) async {
    if (speed < 0 || speed > 2) {
      throw ArgumentError("Speed must be between 0 and 2");
    }
    await videoPlayerController.setSpeed(speed);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.setSpeed,
        parameters: <String, dynamic>{_speedParameter: speed}));
  }

  bool isPlaying() {
    return videoPlayerController.value.isPlaying;
  }

  bool isBuffering() {
    return videoPlayerController.value.isBuffering;
  }

  ///Show or hide controls manually
  void setControlsVisibility(bool isVisible) {
    assert(isVisible != null, "IsVisible can't be null");
    _controlsVisibilityStreamController.add(isVisible);
  }

  ///Enable/disable controls (when enabled = false, controls will be always hidden)
  void setControlsEnabled(bool enabled) {
    assert(enabled != null, "Enabled can't be null");
    if (!enabled) {
      _controlsVisibilityStreamController.add(false);
    }
    _controlsEnabled = enabled;
  }

  ///Internal method, used to trigger CONTROLS_VISIBLE or CONTROLS_HIDDEN event
  ///once controls state changed.
  void toggleControlsVisibility(bool isVisible) {
    assert(isVisible != null, "IsVisible can't be null");
    _postEvent(isVisible
        ? BetterPlayerEvent(BetterPlayerEventType.controlsVisible)
        : BetterPlayerEvent(BetterPlayerEventType.controlsHidden));
  }

  void _postEvent(BetterPlayerEvent betterPlayerEvent) {
    for (final Function eventListener in _eventListeners) {
      if (eventListener != null) {
        eventListener(betterPlayerEvent);
      }
    }
  }

  void _onVideoPlayerChanged() async {
    final currentVideoPlayerValue = videoPlayerController.value;
    if (currentVideoPlayerValue.hasError) {
      _postEvent(
        BetterPlayerEvent(
          BetterPlayerEventType.exception,
          parameters: <String, dynamic>{
            "exception": currentVideoPlayerValue.errorDescription
          },
        ),
      );
    }
    if (currentVideoPlayerValue.initialized &&
        !_hasCurrentDataSourceInitialized) {
      _hasCurrentDataSourceInitialized = true;
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.initialized));
    }
    if (currentVideoPlayerValue.isPip) {
      _wasInPipMode = true;
    } else if (_wasInPipMode) {
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipStop));
      _wasInPipMode = false;
      if (!_wasInFullScreenBeforePiP) {
        exitFullScreen();
      }
      if (_wasControlsEnabledBeforePiP) {
        setControlsEnabled(true);
      }
      videoPlayerController.refresh();
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPositionSelection > 500) {
      _lastPositionSelection = now;
      final Duration currentPositionShifted = Duration(
          milliseconds: currentVideoPlayerValue.position.inMilliseconds + 500);
      if (currentPositionShifted == null ||
          currentVideoPlayerValue.duration == null) {
        return;
      }

      if (currentPositionShifted > currentVideoPlayerValue.duration) {
        _postEvent(
          BetterPlayerEvent(
            BetterPlayerEventType.finished,
            parameters: <String, dynamic>{
              _progressParameter: currentVideoPlayerValue.position,
              _durationParameter: currentVideoPlayerValue.duration
            },
          ),
        );
      } else {
        _postEvent(
          BetterPlayerEvent(
            BetterPlayerEventType.progress,
            parameters: <String, dynamic>{
              _progressParameter: currentVideoPlayerValue.position,
              _durationParameter: currentVideoPlayerValue.duration
            },
          ),
        );
      }
    }
  }

  void addEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.add(eventListener);
  }

  void removeEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.remove(eventListener);
  }

  bool isLiveStream() {
    return _betterPlayerDataSource?.liveStream == true;
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
          Timer.periodic(const Duration(milliseconds: 1000), (_timer) async {
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
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedTrack));

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
        BetterPlayerEvent(BetterPlayerEventType.changedPlayerVisibility));

    if (betterPlayerConfiguration.handleLifecycle) {
      if (betterPlayerConfiguration.playerVisibilityChangedBehavior != null) {
        betterPlayerConfiguration
            .playerVisibilityChangedBehavior(visibilityFraction);
      } else {
        if (visibilityFraction == 0) {
          _wasPlayingBeforePause = isPlaying();
          pause();
        } else {
          if (_wasPlayingBeforePause && !isPlaying()) {
            play();
          }
        }
      }
    }
  }

  ///Set different resolution (quality) for video
  void setResolution(String url) async {
    assert(url != null, "Url can't be null");
    final position = await videoPlayerController.position;
    final wasPlayingBeforeChange = isPlaying();
    cancelFullScreenDismiss = true;
    videoPlayerController.pause();
    await setupDataSource(betterPlayerDataSource.copyWith(url: url));
    videoPlayerController.seekTo(position);
    if (wasPlayingBeforeChange) {
      videoPlayerController.play();
    }
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedResolution));
  }

  ///Setup translations for given locale. In normal use cases it shouldn't be
  ///called manually.
  void setupTranslations(Locale locale) {
    if (locale != null) {
      final String languageCode = locale.languageCode;
      translations = betterPlayerConfiguration.translations?.firstWhere(
              (translations) => translations.languageCode == languageCode,
              orElse: () => null) ??
          _getDefaultTranslations(locale);
    } else {
      BetterPlayerUtils.log("Locale is null. Couldn't setup translations.");
    }
  }

  ///Setup default translations for selected user locale. These translations
  ///are pre-build in.
  BetterPlayerTranslations _getDefaultTranslations(Locale locale) {
    if (locale != null) {
      final String languageCode = locale.languageCode;
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

  bool get hasCurrentDataSourceStarted => _hasCurrentDataSourceStarted;

  void setAppLifecycleState(AppLifecycleState appLifecycleState) {
    if (betterPlayerConfiguration.handleLifecycle) {
      _appLifecycleState = appLifecycleState;
      if (appLifecycleState == AppLifecycleState.resumed) {
        if (_wasPlayingBeforePause) {
          play();
        }
      }
      if (appLifecycleState == AppLifecycleState.paused) {
        _wasPlayingBeforePause = isPlaying();
        pause();
      }
    }
  }

  // ignore: use_setters_to_change_properties
  ///Setup overridden aspect ratio.
  void setOverriddenAspectRatio(double aspectRatio) {
    _overriddenAspectRatio = aspectRatio;
  }

  ///Get aspect ratio used in current video. If aspect ratio is null, then
  ///aspect ratio from BetterPlayerConfiguration will be used. Otherwise
  ///[_overriddenAspectRatio] will be used.
  double getAspectRatio() {
    return _overriddenAspectRatio ?? betterPlayerConfiguration.aspectRatio;
  }

  ///Enable Picture in Picture (PiP) mode. [betterPlayerGlobalKey] is required
  ///to open PiP mode in iOS. When device is not supported, PiP mode won't be
  ///open.
  Future<void> enablePictureInPicture(GlobalKey betterPlayerGlobalKey) async {
    assert(
        betterPlayerGlobalKey != null, "BetterPlayerGlobalKey can't be null");
    if (await videoPlayerController.isPictureInPictureSupported()) {
      _wasInFullScreenBeforePiP = _isFullScreen;
      _wasControlsEnabledBeforePiP = _controlsEnabled;
      setControlsEnabled(false);
      if (Platform.isAndroid) {
        _wasInFullScreenBeforePiP = _isFullScreen;
        await videoPlayerController.enablePictureInPicture(
            left: 0, top: 0, width: 0, height: 0);
        enterFullScreen();
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pipStart));
        return;
      }
      if (Platform.isIOS) {
        final RenderBox renderBox = betterPlayerGlobalKey.currentContext
            .findRenderObject() as RenderBox;
        if (renderBox == null) {
          BetterPlayerUtils.log(
              "Can't show PiP. RenderBox is null. Did you provide valid global"
              " key?");
          return;
        }
        final Offset position = renderBox.localToGlobal(Offset.zero);
        return videoPlayerController.enablePictureInPicture(
          left: position.dx,
          top: position.dy,
          width: renderBox.size.width,
          height: renderBox.size.height,
        );
      } else {
        BetterPlayerUtils.log("Unsupported PiP in current platform.");
      }
    } else {
      BetterPlayerUtils.log(
          "Picture in picture is not supported in this device. If you're "
          "using Android, please check if you're using activity v2 "
          "embedding.");
    }
  }

  ///Disable Picture in Picture mode if it's enabled.
  Future<void> disablePictureInPicture() {
    return videoPlayerController.disablePictureInPicture();
  }

  ///Set GlobalKey of BetterPlayer. Used in PiP methods called from controls.
  void setBetterPlayerGlobalKey(GlobalKey betterPlayerGlobalKey) {
    assert(
        betterPlayerGlobalKey != null, "BetterPlayerGlobalKey can't be null");
    _betterPlayerGlobalKey = betterPlayerGlobalKey;
  }

  ///Check if picture in picture mode is supported in this device.
  Future<bool> isPictureInPictureSupported() async {
    return videoPlayerController.isPictureInPictureSupported();
  }

  ///Handle VideoEvent when remote controls notification / PiP is shown
  void _handleVideoEvent(VideoEvent event) {
    switch (event.eventType) {
      case VideoEventType.play:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
        break;
      case VideoEventType.pause:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.pause));
        break;
      case VideoEventType.seek:
        _postEvent(BetterPlayerEvent(BetterPlayerEventType.seekTo));
        break;
      default:

        ///TODO: Handle when needed
        break;
    }
  }

  @override
  void dispose() {
    if (!betterPlayerConfiguration.autoDispose) {
      return;
    }
    if (!_disposed) {
      _eventListeners.clear();
      videoPlayerController?.removeListener(_fullScreenListener);
      videoPlayerController?.removeListener(_onVideoPlayerChanged);
      videoPlayerController?.dispose();
      _nextVideoTimer?.cancel();
      nextVideoTimeStreamController.close();
      _controlsVisibilityStreamController.close();
      _videoEventStreamSubscription?.cancel();
      _disposed = true;

      ///Delete files async
      _tempFiles?.forEach((file) => file.delete());
      super.dispose();
    }
  }
}
