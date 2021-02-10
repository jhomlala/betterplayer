// Dart imports:
import 'dart:async';
import 'dart:io';

// Project imports:
import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_configuration.dart';
import 'package:better_player/src/configuration/better_player_event.dart';
import 'package:better_player/src/configuration/better_player_event_type.dart';
import 'package:better_player/src/configuration/better_player_translations.dart';
import 'package:better_player/src/configuration/better_player_video_format.dart';
import 'package:better_player/src/core/better_player_controller_provider.dart';

// Flutter imports:
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/hls/better_player_hls_audio_track.dart';
import 'package:better_player/src/hls/better_player_hls_track.dart';
import 'package:better_player/src/hls/better_player_hls_utils.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:path_provider/path_provider.dart';

///Class used to control overall Better Player behavior. Main class to change
///state of Better Player.
class BetterPlayerController extends ChangeNotifier {
  static const String _durationParameter = "duration";
  static const String _progressParameter = "progress";
  static const String _volumeParameter = "volume";
  static const String _speedParameter = "speed";
  static const String _hlsExtension = "m3u8";

  ///General configuration used in controller instance.
  final BetterPlayerConfiguration betterPlayerConfiguration;

  ///Playlist configuration used in controller instance.
  final BetterPlayerPlaylistConfiguration betterPlayerPlaylistConfiguration;

  ///List of event listeners, which listen to events.
  final List<Function> _eventListeners = [];

  ///List of files to delete once player disposes.
  final List<File> _tempFiles = [];

  ///Stream controller which emits stream when control visibility changes.
  final StreamController<bool> _controlsVisibilityStreamController =
      StreamController.broadcast();

  ///Instance of video player controller which is adapter used to communicate
  ///between flutter high level code and lower level native code.
  VideoPlayerController videoPlayerController;

  /// Defines a event listener where video player events will be send.
  Function(BetterPlayerEvent) get eventListener =>
      betterPlayerConfiguration.eventListener;

  ///Flag used to store full screen mode state.
  bool _isFullScreen = false;

  ///Flag used to store full screen mode state.
  bool get isFullScreen => _isFullScreen;

  ///Time when last progress event was sent
  int _lastPositionSelection = 0;

  ///Currently used data source in player.
  BetterPlayerDataSource _betterPlayerDataSource;

  ///Currently used data source in player.
  BetterPlayerDataSource get betterPlayerDataSource => _betterPlayerDataSource;

  ///List of BetterPlayerSubtitlesSources.
  final List<BetterPlayerSubtitlesSource> _betterPlayerSubtitlesSourceList = [];

  ///List of BetterPlayerSubtitlesSources.
  List<BetterPlayerSubtitlesSource> get betterPlayerSubtitlesSourceList =>
      _betterPlayerSubtitlesSourceList;
  BetterPlayerSubtitlesSource _betterPlayerSubtitlesSource;

  ///Currently used subtitles source.
  BetterPlayerSubtitlesSource get betterPlayerSubtitlesSource =>
      _betterPlayerSubtitlesSource;

  ///Subtitles lines for current data source.
  List<BetterPlayerSubtitle> subtitlesLines = [];

  ///List of tracks available for current data source. Used only for HLS.
  List<BetterPlayerHlsTrack> _betterPlayerTracks = [];

  ///List of tracks available for current data source. Used only for HLS.
  List<BetterPlayerHlsTrack> get betterPlayerTracks => _betterPlayerTracks;

  ///Currently selected player track. Used only for HLS.
  BetterPlayerHlsTrack _betterPlayerTrack;

  ///Currently selected player track. Used only for HLS.
  BetterPlayerHlsTrack get betterPlayerTrack => _betterPlayerTrack;

  ///Timer for next video. Used in playlist.
  Timer _nextVideoTimer;

  ///Time for next video.
  int _nextVideoTime;

  ///Stream controller which emits next video time.
  StreamController<int> nextVideoTimeStreamController =
      StreamController.broadcast();

  ///Has player been disposed.
  bool _disposed = false;

  ///Was player playing before automatic pause.
  bool _wasPlayingBeforePause;

  ///Internal flag used to cancel dismiss of the full screen. Used when user
  ///switches quality (track or resolution) of the video. You should ignore it.
  bool cancelFullScreenDismiss = false;

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

  ///Are controls always visible
  bool _controlsAlwaysVisible = false;

  ///Are controls always visible
  bool get controlsAlwaysVisible => _controlsAlwaysVisible;

  ///List of all possible audio tracks returned from HLS stream
  List<BetterPlayerHlsAudioTrack> _betterPlayerAudioTracks;

  ///List of all possible audio tracks returned from HLS stream
  List<BetterPlayerHlsAudioTrack> get betterPlayerAudioTracks =>
      _betterPlayerAudioTracks;

  ///Selected HLS audio track
  BetterPlayerHlsAudioTrack _betterPlayerHlsAudioTrack;

  ///Selected HLS audio track
  BetterPlayerHlsAudioTrack get betterPlayerAudioTrack =>
      _betterPlayerHlsAudioTrack;

  ///Selected videoPlayerValue when error occured.
  VideoPlayerValue _videoPlayerValueOnError;

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

  ///Get BetterPlayerController from context. Used in InheritedWidget.
  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>();

    return betterPLayerControllerProvider.controller;
  }

  ///Setup new data source in Better Player.
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

    if (_isDataSourceHls(betterPlayerDataSource)) {
      _setupHlsDataSource().then((dynamic value) {
        _setupSubtitles();
      });
    } else {
      _setupSubtitles();
    }

    ///Process data source
    await _setupDataSource(betterPlayerDataSource);
  }

  ///Configure subtitles based on subtitles source.
  void _setupSubtitles() {
    _betterPlayerSubtitlesSourceList.add(
      BetterPlayerSubtitlesSource(type: BetterPlayerSubtitlesSourceType.none),
    );
    final defaultSubtitle = _betterPlayerSubtitlesSourceList.firstWhere(
        (element) => element.selectedByDefault == true,
        orElse: () => null);

    ///Setup subtitles (none is default)
    setupSubtitleSource(
        defaultSubtitle ?? _betterPlayerSubtitlesSourceList.last,
        sourceInitialize: true);
  }

  ///Check if given [betterPlayerDataSource] is HLS-type data source.
  bool _isDataSourceHls(BetterPlayerDataSource betterPlayerDataSource) =>
      betterPlayerDataSource.url.contains(_hlsExtension) ||
      betterPlayerDataSource.videoFormat == BetterPlayerVideoFormat.hls;

  ///Configure HLS data source based on provided data source and configuration.
  ///This method configures tracks, subtitles and audio tracks from given
  ///master playlist.
  Future _setupHlsDataSource() async {
    final String hlsData =
        await BetterPlayerHlsUtils.getDataFromUrl(betterPlayerDataSource.url);
    if (hlsData != null) {
      /// Load hls tracks
      if (_betterPlayerDataSource?.useHlsTracks == true) {
        _betterPlayerTracks = await BetterPlayerHlsUtils.parseTracks(
            hlsData, betterPlayerDataSource.url);
      }

      /// Load hls subtitles
      if (betterPlayerDataSource?.useHlsSubtitles == true) {
        final hlsSubtitles = await BetterPlayerHlsUtils.parseSubtitles(
            hlsData, betterPlayerDataSource.url);
        hlsSubtitles?.forEach((hlsSubtitle) {
          _betterPlayerSubtitlesSourceList.add(
            BetterPlayerSubtitlesSource(
                type: BetterPlayerSubtitlesSourceType.network,
                name: hlsSubtitle.name,
                urls: hlsSubtitle.realUrls),
          );
        });
      }

      ///Load audio tracks
      if (betterPlayerDataSource?.useHlsAudioTracks == true &&
          _isDataSourceHls(betterPlayerDataSource)) {
        _betterPlayerAudioTracks = await BetterPlayerHlsUtils.parseLanguages(
            hlsData, betterPlayerDataSource.url);
      }
    }
  }

  ///Setup subtitles to be displayed from given subtitle source
  Future<void> setupSubtitleSource(BetterPlayerSubtitlesSource subtitlesSource,
      {bool sourceInitialize = false}) async {
    assert(subtitlesSource != null, "SubtitlesSource can't be null");
    _betterPlayerSubtitlesSource = subtitlesSource;
    subtitlesLines.clear();
    if (subtitlesSource.type != BetterPlayerSubtitlesSourceType.none) {
      final subtitlesParsed =
          await BetterPlayerSubtitlesFactory.parseSubtitles(subtitlesSource);
      subtitlesLines.addAll(subtitlesParsed);
    }

    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedSubtitles));
    if (!_disposed && !sourceInitialize) {
      cancelFullScreenDismiss = true;
      notifyListeners();
    }
  }

  ///Get VideoFormat from BetterPlayerVideoFormat (adapter method which translates
  ///to video_player supported format).
  VideoFormat _getVideoFormat(BetterPlayerVideoFormat betterPlayerVideoFormat) {
    if (betterPlayerVideoFormat == null) {
      return null;
    }
    switch (betterPlayerVideoFormat) {
      case BetterPlayerVideoFormat.dash:
        return VideoFormat.dash;
      case BetterPlayerVideoFormat.hls:
        return VideoFormat.hls;
      case BetterPlayerVideoFormat.ss:
        return VideoFormat.ss;
      case BetterPlayerVideoFormat.other:
        return VideoFormat.other;
    }
    return null;
  }

  ///Internal method which invokes videoPlayerController source setup.
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
          formatHint: _getVideoFormat(_betterPlayerDataSource.videoFormat),
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
    await _initializeVideo();
  }

  ///Create file from provided list of bytes. File will be created in temporary
  ///directory.
  Future<File> _createFile(List<int> bytes) async {
    final String dir = (await getTemporaryDirectory()).path;
    final File temp = File('$dir/better_player_${DateTime.now()}.temp');
    await temp.writeAsBytes(bytes);
    return temp;
  }

  ///Initializes video based on configuration. Invoke actions which need to be
  ///run on player start.
  Future _initializeVideo() async {
    await videoPlayerController.setLooping(betterPlayerConfiguration.looping);
    _videoEventStreamSubscription = videoPlayerController
        .videoEventStreamController.stream
        .listen(_handleVideoEvent);
    final fullScreenByDefault = betterPlayerConfiguration.fullScreenByDefault;
    if (betterPlayerConfiguration.autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await play();
    } else {
      if (fullScreenByDefault) {
        videoPlayerController.addListener(_onFullScreenStateChanged);
      }
    }

    final startAt = betterPlayerConfiguration.startAt;
    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }
  }

  ///Method which is invoked when full screen changes.
  Future<void> _onFullScreenStateChanged() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_onFullScreenStateChanged);
    }
  }

  ///Enables full screen mode in player. This will trigger route change.
  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  ///Disables full screen mode in player. This will trigger route change.
  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  ///Enables/disables full screen mode based on current fullscreen state.
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  ///Start video playback. Play will be triggered only if current lifecycle state
  ///is resumed.
  Future<void> play() async {
    if (_appLifecycleState == AppLifecycleState.resumed) {
      await videoPlayerController.play();
      _hasCurrentDataSourceStarted = true;
      _wasPlayingBeforePause = null;
      _postEvent(BetterPlayerEvent(BetterPlayerEventType.play));
    }
  }

  ///Enables/disables looping (infinity playback) mode.
  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  ///Stop video playback.
  Future<void> pause() async {
    await videoPlayerController.pause();
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.pause));
  }

  ///Move player to specific position/moment of the video.
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

  ///Set volume of player. Allows values from 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError("Volume must be between 0.0 and 1.0");
    }
    await videoPlayerController.setVolume(volume);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.setVolume,
        parameters: <String, dynamic>{_volumeParameter: volume}));
  }

  ///Set playback speed of video. Allows to set speed value between 0 and 2.
  Future<void> setSpeed(double speed) async {
    if (speed < 0 || speed > 2) {
      throw ArgumentError("Speed must be between 0 and 2");
    }
    await videoPlayerController.setSpeed(speed);
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.setSpeed,
        parameters: <String, dynamic>{_speedParameter: speed}));
  }

  ///Flag which determines whenever player is playing or not.
  bool isPlaying() {
    return videoPlayerController.value.isPlaying;
  }

  ///Flag which determines whenever player is loading video data or not.
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

  ///Send player event. Shouldn't be used manually.
  void postEvent(BetterPlayerEvent betterPlayerEvent) {
    _postEvent(betterPlayerEvent);
  }

  ///Send player event to all listeners.
  void _postEvent(BetterPlayerEvent betterPlayerEvent) {
    for (final Function eventListener in _eventListeners) {
      if (eventListener != null) {
        eventListener(betterPlayerEvent);
      }
    }
  }

  ///Listener used to handle video player changes.
  void _onVideoPlayerChanged() async {
    final currentVideoPlayerValue = videoPlayerController.value;
    if (currentVideoPlayerValue.hasError) {
      _videoPlayerValueOnError ??= currentVideoPlayerValue;
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

  ///Add event listener which listens to player events.
  void addEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.add(eventListener);
  }

  ///Remove event listener. This method should be called once you're disposing
  ///Better Player.
  void removeEventsListener(Function(BetterPlayerEvent) eventListener) {
    _eventListeners.remove(eventListener);
  }

  ///Flag which determines whenever player is playing live data source.
  bool isLiveStream() {
    return _betterPlayerDataSource?.liveStream == true;
  }

  ///Flag which determines whenever player data source has been initialized.
  bool isVideoInitialized() {
    return videoPlayerController.value.initialized;
  }

  ///Start timer which will trigger next video. Used in playlist. Do not use
  ///manually.
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

  ///Cancel next video timer. Used in playlist. Do not use manually.
  void cancelNextVideoTimer() {
    _nextVideoTime = null;
    nextVideoTimeStreamController.add(_nextVideoTime);
    _nextVideoTimer?.cancel();
    _nextVideoTimer = null;
  }

  ///Play next video form playlist. Do not use manually.
  void playNextVideo() {
    _nextVideoTime = 0;
    nextVideoTimeStreamController.add(_nextVideoTime);
    cancelNextVideoTimer();
  }

  ///Setup track parameters for currently played video. Can be used only for HLS
  ///data source.
  void setTrack(BetterPlayerHlsTrack track) {
    _postEvent(BetterPlayerEvent(BetterPlayerEventType.changedTrack));

    ///Default element clicked:
    if (track.width == 0 && track.height == 0 && track.bitrate == 0) {
      _betterPlayerTrack = null;
      return;
    }

    videoPlayerController.setTrackParameters(
        track.width, track.height, track.bitrate);
    _betterPlayerTrack = track;
  }

  ///Listener which handles state of player visibility. If player visibility is
  ///below 0.0 then video will be paused. When value is greater than 0, video
  ///will play again. If there's different handler of visibility then it will be
  ///used. If showNotification is set in data source or handleLifecycle is false
  /// then this logic will be ignored.
  void onPlayerVisibilityChanged(double visibilityFraction) async {
    if (_disposed) {
      return;
    }
    _postEvent(
        BetterPlayerEvent(BetterPlayerEventType.changedPlayerVisibility));

    if (!_betterPlayerDataSource.notificationConfiguration.showNotification &&
        betterPlayerConfiguration.handleLifecycle) {
      if (betterPlayerConfiguration.playerVisibilityChangedBehavior != null) {
        betterPlayerConfiguration
            .playerVisibilityChangedBehavior(visibilityFraction);
      } else {
        if (visibilityFraction == 0) {
          _wasPlayingBeforePause ??= isPlaying();
          pause();
        } else {
          if (_wasPlayingBeforePause == true && !isPlaying()) {
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

  ///Flag which determines whenever current data source has started.
  bool get hasCurrentDataSourceStarted => _hasCurrentDataSourceStarted;

  ///Set current lifecycle state. If state is [AppLifecycleState.resumed] then
  ///player starts playing again. if lifecycle is in [AppLifecycleState.paused]
  ///state, then video playback will stop. If showNotification is set in data
  ///source or handleLifecycle is false then this logic will be ignored.
  void setAppLifecycleState(AppLifecycleState appLifecycleState) {
    if (!_betterPlayerDataSource.notificationConfiguration.showNotification &&
        betterPlayerConfiguration.handleLifecycle) {
      _appLifecycleState = appLifecycleState;
      if (appLifecycleState == AppLifecycleState.resumed) {
        if (_wasPlayingBeforePause == true) {
          play();
        }
      }
      if (appLifecycleState == AppLifecycleState.paused) {
        _wasPlayingBeforePause ??= isPlaying();
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
  void _handleVideoEvent(VideoEvent event) async {
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
      case VideoEventType.completed:
        final videoValue = videoPlayerController.value;
        _postEvent(
          BetterPlayerEvent(
            BetterPlayerEventType.finished,
            parameters: <String, dynamic>{
              _progressParameter: videoValue.position,
              _durationParameter: videoValue.duration
            },
          ),
        );
        break;
      default:

        ///TODO: Handle when needed
        break;
    }
  }

  ///Setup controls always visible mode
  void setControlsAlwaysVisible(bool controlsAlwaysVisible) {
    assert(
        controlsAlwaysVisible != null, "ControlsAlwaysVisible can't be null");
    _controlsAlwaysVisible = controlsAlwaysVisible;
    _controlsVisibilityStreamController.add(controlsAlwaysVisible);
  }

  ///Retry data source if playback failed.
  Future retryDataSource() async {
    await _setupDataSource(_betterPlayerDataSource);
    if (_videoPlayerValueOnError != null) {
      final position = _videoPlayerValueOnError.position;
      await seekTo(position);
      await play();
      _videoPlayerValueOnError = null;
    }
  }

  ///Set [audioTrack] in player. Works only for HLS streams.
  void setAudioTrack(BetterPlayerHlsAudioTrack audioTrack) {
    assert(audioTrack != null, "AudioTrack can't be null");

    if (audioTrack.language == null) {
      _betterPlayerHlsAudioTrack = null;
      return;
    }

    _betterPlayerHlsAudioTrack = audioTrack;
    videoPlayerController.setAudioTrack(audioTrack.label, audioTrack.id);
  }

  ///Dispose BetterPlayerController. When [forceDispose] parameter is true, then
  ///autoDispose parameter will be overridden and controller will be disposed
  ///(if it wasn't disposed before).
  @override
  void dispose({bool forceDispose = false}) {
    if (!betterPlayerConfiguration.autoDispose && !forceDispose) {
      return;
    }
    if (!_disposed) {
      pause();
      _eventListeners.clear();
      videoPlayerController?.removeListener(_onFullScreenStateChanged);
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
