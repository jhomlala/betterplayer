import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:better_player/src/engine/player_engine_controller.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/subtitles/player_subtitle.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

part 'mixins/player_data_source_mixin.dart';
part 'mixins/player_playback_mixin.dart';
part 'mixins/player_track_mixin.dart';
part 'mixins/player_subtitle_mixin.dart';
part 'mixins/player_playlist_mixin.dart';
part 'mixins/player_view_state_mixin.dart';
part 'mixins/player_cache_mixin.dart';
part 'mixins/player_translations_mixin.dart';
part 'mixins/player_events_mixin.dart';

///Class used to control overall Better Player behavior. Main class to change
///state of Better Player.
class BetterPlayerController {
  BetterPlayerController(
    this.betterPlayerConfiguration, {
    this.betterPlayerPlaylistConfiguration,
    PlayerDataSource? betterPlayerDataSource,
    @visibleForTesting PlayerEngineController? playerEngineController,
  }) : _engine = playerEngineController {
    PlayerLogger.setup(betterPlayerConfiguration.playerLogConfiguration);
    PlayerLogger.info(message: 'Created', textureId: textureId);
    _betterPlayerControlsConfiguration =
        betterPlayerConfiguration.controlsConfiguration;
    _eventListeners.add(eventListener);
    if (_engine != null) {
      _engine!.addListener(_onVideoPlayerChanged);
    }
    if (betterPlayerDataSource != null) {
      setupDataSource(betterPlayerDataSource);
    }
  }

  static const String _durationParameter = 'duration';
  static const String _progressParameter = 'progress';
  static const String _bufferedParameter = 'buffered';
  static const String _volumeParameter = 'volume';
  static const String _speedParameter = 'speed';
  static const String _dataSourceParameter = 'dataSource';
  static const String _authorizationHeader = 'Authorization';

  ///General configuration used in controller instance.
  final PlayerConfiguration betterPlayerConfiguration;

  ///Playlist configuration used in controller instance.
  final PlayerPlaylistConfiguration? betterPlayerPlaylistConfiguration;

  ///List of event listeners, which listen to events.
  final List<Function(PlayerEvent)?> _eventListeners = [];

  ///List of files to delete once player disposes.
  final List<File> _tempFiles = [];

  ///Stream controller which emits stream when control visibility changes.
  final StreamController<bool> _controlsVisibilityStreamController =
      StreamController.broadcast();

  ///Instance of video player controller which is adapter used to communicate
  ///between flutter high level code and lower level native code.
  PlayerEngineController? _engine;

  ///Controls configuration
  late PlayerControlsConfiguration _betterPlayerControlsConfiguration;

  PlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _betterPlayerControlsConfiguration;

  ///Expose all active eventListeners
  List<Function(PlayerEvent)?> get eventListeners => _eventListeners.sublist(1);

  /// Defines a event listener where video player events will be send.
  Function(PlayerEvent)? get eventListener =>
      betterPlayerConfiguration.eventListener;

  ///Flag used to store full screen mode state.
  bool _isFullScreen = false;

  ///Flag used to store full screen mode state.
  bool get isFullScreen => _isFullScreen;

  ///Time when last progress event was sent
  int _lastPositionSelection = 0;

  ///Currently used data source in player.
  PlayerDataSource? _betterPlayerDataSource;

  ///Currently used data source in player.
  PlayerDataSource? get betterPlayerDataSource => _betterPlayerDataSource;

  ///List of PlayerSubtitlesSources.
  final List<PlayerSubtitlesSource> _betterPlayerSubtitlesSourceList = [];

  ///List of PlayerSubtitlesSources.
  List<PlayerSubtitlesSource> get betterPlayerSubtitlesSourceList =>
      _betterPlayerSubtitlesSourceList;
  PlayerSubtitlesSource? _betterPlayerSubtitlesSource;

  ///Currently used subtitles source.
  PlayerSubtitlesSource? get betterPlayerSubtitlesSource =>
      _betterPlayerSubtitlesSource;

  ///Subtitles lines for current data source.
  List<PlayerSubtitle> subtitlesLines = [];

  ///List of tracks available for current data source. Used only for HLS / DASH.
  List<PlayerAsmsTrack> _betterPlayerAsmsTracks = [];

  ///List of tracks available for current data source. Used only for HLS / DASH.
  List<PlayerAsmsTrack> get betterPlayerAsmsTracks => _betterPlayerAsmsTracks;

  ///Currently selected player track. Used only for HLS / DASH.
  PlayerAsmsTrack? _betterPlayerAsmsTrack;

  ///Currently selected player track. Used only for HLS / DASH.
  PlayerAsmsTrack? get betterPlayerAsmsTrack => _betterPlayerAsmsTrack;

  ///Timer for next video. Used in playlist.
  Timer? _nextVideoTimer;

  ///Time for next video.
  int? _nextVideoTime;

  ///Stream controller which emits next video time.
  final StreamController<int?> _nextVideoTimeStreamController =
      StreamController.broadcast();

  Stream<int?> get nextVideoTimeStream => _nextVideoTimeStreamController.stream;

  ///Has player been disposed.
  bool _disposed = false;

  ///Was player playing before automatic pause.
  bool? _wasPlayingBeforePause;

  ///Currently used translations
  PlayerTranslations translations = PlayerTranslations();

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
  double? _overriddenAspectRatio;

  ///Overridden fit which will be used instead of fit passed in configuration.
  BoxFit? _overriddenFit;

  ///Was Picture in Picture opened.
  bool _wasInPipMode = false;

  ///Was player in fullscreen before Picture in Picture opened.
  bool _wasInFullScreenBeforePiP = false;

  ///Was controls enabled before Picture in Picture opened.
  bool _wasControlsEnabledBeforePiP = false;

  ///GlobalKey of the BetterPlayer widget
  GlobalKey? _betterPlayerGlobalKey;

  ///Getter of the GlobalKey
  GlobalKey? get betterPlayerGlobalKey => _betterPlayerGlobalKey;

  ///StreamSubscription for VideoEvent listener
  StreamSubscription<VideoEvent>? _videoEventStreamSubscription;

  bool _controlsAlwaysVisible = false;

  ///Are controls always visible
  bool get controlsAlwaysVisible => _controlsAlwaysVisible;

  ///List of all possible audio tracks returned from ASMS stream
  List<PlayerAsmsAudioTrack> _betterPlayerAsmsAudioTracks = [];

  ///List of all possible audio tracks returned from ASMS stream
  List<PlayerAsmsAudioTrack> get betterPlayerAsmsAudioTracks =>
      _betterPlayerAsmsAudioTracks;

  ///Selected ASMS audio track
  PlayerAsmsAudioTrack? _betterPlayerAsmsAudioTrack;

  ///Selected ASMS audio track
  PlayerAsmsAudioTrack? get betterPlayerAsmsAudioTrack =>
      _betterPlayerAsmsAudioTrack;

  /// The id of a texture that hasn't been initialized is null.
  int? get textureId => _engine?.textureId;

  /// Whether the engine has been created. False before [setupDataSource] is called.
  bool get isEngineReady => _engine != null;

  /// Whether the video has been initialized (duration is known).
  bool get isInitialized => _engine?.value.initialized ?? false;

  /// Total duration of the current video. Null until initialized.
  Duration? get duration => _engine?.value.duration;

  /// The full engine state snapshot. Prefer individual getters for new code.
  VideoPlayerValue? get playerValue => _engine?.value;

  /// Current playback position.
  Future<Duration?> get position async => _engine?.position;

  /// Absolute position in a live stream (EXT-X-PROGRAM-DATE-TIME).
  Future<DateTime?> get absolutePosition async => _engine?.absolutePosition;

  final List<VoidCallback> _videoListeners = [];

  /// Add listener for video player state changes.
  void addVideoListener(VoidCallback listener) {
    _videoListeners.add(listener);
  }

  /// Remove listener for video player state changes.
  void removeVideoListener(VoidCallback listener) {
    _videoListeners.remove(listener);
  }

  /// Get current video player value (state).
  VideoPlayerValue? get videoPlayerValue => _engine?.value;

  /// Build the internal VideoPlayer view.
  Widget buildVideoPlayerView() {
    if (_engine == null) {
      return const SizedBox();
    }
    return PlayerEngineView(_engine);
  }

  ///Selected videoPlayerValue when error occurred.
  VideoPlayerValue? _videoPlayerValueOnError;

  ///Flag which holds information about player visibility
  bool _isPlayerVisible = true;

  final StreamController<PlayerControllerEvent>
  _controllerEventStreamController = StreamController.broadcast();

  ///Stream of internal controller events. Shouldn't be used inside app. For
  ///normal events, use eventListener.
  Stream<PlayerControllerEvent> get controllerEventStream =>
      _controllerEventStreamController.stream;

  ///Flag which determines whether are ASMS segments loading
  bool _asmsSegmentsLoading = false;

  ///List of loaded ASMS segments
  final List<String> _asmsSegmentsLoaded = [];

  ///Currently displayed [PlayerSubtitle].
  PlayerSubtitle? renderedSubtitle;

  ///Get BetterPlayerController from context. Used in InheritedWidget.
  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>()!;

    return betterPLayerControllerProvider.controller;
  }

  ///Listener used to handle video player changes.
  Future<void> _onVideoPlayerChanged() async {
    for (final listener in List<VoidCallback>.from(_videoListeners)) {
      listener();
    }

    final currentVideoPlayerValue =
        _engine?.value ?? VideoPlayerValue(duration: const Duration());

    if (currentVideoPlayerValue.initialized &&
        !_hasCurrentDataSourceInitialized) {
      PlayerLogger.info(
        message: 'Video player initialized',
        textureId: textureId,
      );
      _hasCurrentDataSourceInitialized = true;
      _postEvent(PlayerEvent(PlayerEventType.initialized));
    }
    if (currentVideoPlayerValue.isPip) {
      _wasInPipMode = true;
    } else if (_wasInPipMode) {
      _postEvent(PlayerEvent(PlayerEventType.pipStop));
      _wasInPipMode = false;
      if (!_wasInFullScreenBeforePiP) {
        exitFullScreen();
      }
      if (_wasControlsEnabledBeforePiP) {
        setControlsEnabled(true);
      }
      _engine?.refresh();
    }

    if (_betterPlayerSubtitlesSource?.asmsIsSegmented == true) {
      _loadAsmsSubtitlesSegments(currentVideoPlayerValue.position);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPositionSelection > 500) {
      _lastPositionSelection = now;
      _postEvent(
        PlayerEvent(
          PlayerEventType.progress,
          parameters: <String, dynamic>{
            _progressParameter: currentVideoPlayerValue.position,
            _durationParameter: currentVideoPlayerValue.duration,
          },
        ),
      );
    }
  }

  ///Flag which determines whenever player is playing live data source.
  bool isLiveStream() {
    if (_betterPlayerDataSource == null) {
      PlayerLogger.warning(
        message: 'The data source has not been initialized',
        textureId: textureId,
      );
      throw StateError('The data source has not been initialized');
    }
    return _betterPlayerDataSource!.liveStream == true;
  }

  ///Flag which determines whenever player data source has been initialized.
  bool? isVideoInitialized() {
    if (_engine == null) {
      PlayerLogger.warning(
        message: 'The data source has not been initialized',
        textureId: textureId,
      );
      throw StateError('The data source has not been initialized');
    }
    return _engine?.value.initialized;
  }

  ///Flag which determines whenever current data source has started.
  bool get hasCurrentDataSourceStarted => _hasCurrentDataSourceStarted;

  ///Handle VideoEvent when remote controls notification / PiP is shown
  Future<void> _handleVideoEvent(VideoEvent event) async {
    PlayerLogger.debug(
      message: 'Video event: ${event.eventType}',
      textureId: textureId,
    );
    switch (event.eventType) {
      case VideoEventType.play:
        _postEvent(PlayerEvent(PlayerEventType.play));
      case VideoEventType.pause:
        _postEvent(PlayerEvent(PlayerEventType.pause));
      case VideoEventType.seek:
        _postEvent(PlayerEvent(PlayerEventType.seekTo));
      case VideoEventType.completed:
        final videoValue = _engine?.value;
        _postEvent(
          PlayerEvent(
            PlayerEventType.finished,
            parameters: <String, dynamic>{
              _progressParameter: videoValue?.position,
              _durationParameter: videoValue?.duration,
            },
          ),
        );
      case VideoEventType.bufferingStart:
        _postEvent(PlayerEvent(PlayerEventType.bufferingStart));
      case VideoEventType.bufferingUpdate:
        _postEvent(
          PlayerEvent(
            PlayerEventType.bufferingUpdate,
            parameters: <String, dynamic>{
              _bufferedParameter: event.buffered,
            },
          ),
        );
      case VideoEventType.bufferingEnd:
        _postEvent(PlayerEvent(PlayerEventType.bufferingEnd));
      default:

        ///TODO: Handle when needed
        break;
    }
  }

  ///Retry data source if playback failed.
  Future retryDataSource() async {
    PlayerLogger.warning(
      message: 'Retrying data source',
      textureId: textureId,
    );
    await _setupDataSource(_betterPlayerDataSource!);
    if (_videoPlayerValueOnError != null) {
      final position = _videoPlayerValueOnError!.position;
      await seekTo(position);
      await play();
      _videoPlayerValueOnError = null;
    }
  }

  ///Build headers map that will be used to setup video player controller. Apply
  ///DRM headers if available.
  Map<String, String?> _getHeaders() {
    final headers = betterPlayerDataSource!.headers ?? {};
    if (betterPlayerDataSource?.drmConfiguration?.drmType == DrmType.token &&
        betterPlayerDataSource?.drmConfiguration?.token != null) {
      headers[_authorizationHeader] =
          betterPlayerDataSource!.drmConfiguration!.token!;
    }
    return headers;
  }

  /// Sets the new [betterPlayerControlsConfiguration] instance in the
  /// controller.
  void setPlayerControlsConfiguration(
    PlayerControlsConfiguration betterPlayerControlsConfiguration,
  ) {
    _betterPlayerControlsConfiguration = betterPlayerControlsConfiguration;
  }

  ///Dispose BetterPlayerController. When [forceDispose] parameter is true, then
  ///autoDispose parameter will be overridden and controller will be disposed
  ///(if it wasn't disposed before).
  void dispose({bool forceDispose = false}) {
    PlayerLogger.info(message: 'Disposed', textureId: textureId);
    if (!betterPlayerConfiguration.autoDispose && !forceDispose) {
      return;
    }
    if (!_disposed) {
      if (_engine != null) {
        pause();
        _engine!.removeListener(_onFullScreenStateChanged);
        _engine!.removeListener(_onVideoPlayerChanged);
        _engine!.dispose();
      }
      _eventListeners.clear();
      _nextVideoTimer?.cancel();
      _nextVideoTimeStreamController.close();
      _controlsVisibilityStreamController.close();
      _videoEventStreamSubscription?.cancel();
      _disposed = true;
      _controllerEventStreamController.close();

      ///Delete files async
      for (final file in _tempFiles) {
        file.delete();
      }
    }
  }
}
