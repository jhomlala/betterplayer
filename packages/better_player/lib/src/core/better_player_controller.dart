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

part 'extensions/player_data_source_extension.dart';
part 'extensions/player_playback_extension.dart';
part 'extensions/player_track_extension.dart';
part 'extensions/player_subtitle_extension.dart';
part 'extensions/player_playlist_extension.dart';
part 'extensions/player_view_state_extension.dart';
part 'extensions/player_cache_extension.dart';
part 'extensions/player_translations_extension.dart';
part 'extensions/player_events_extension.dart';

///Class used to control overall Better Player behavior. Main class to change
///state of Better Player.
class BetterPlayerController {
  /// Parameter for duration event
  static const String _durationParameter = 'duration';

  /// Parameter for progress event
  static const String _progressParameter = 'progress';

  /// Parameter for buffered event
  static const String _bufferedParameter = 'buffered';

  /// Parameter for volume event
  static const String _volumeParameter = 'volume';

  /// Parameter for speed event
  static const String _speedParameter = 'speed';

  /// Parameter for data source event
  static const String _dataSourceParameter = 'dataSource';

  /// Authorization header key
  static const String _authorizationHeader = 'Authorization';

  ///General configuration used in controller instance.
  final PlayerConfiguration betterPlayerConfiguration;

  ///Playlist configuration used in controller instance.
  final PlayerPlaylistConfiguration? betterPlayerPlaylistConfiguration;

  ///Instance of video player controller which is adapter used to communicate
  ///between flutter high level code and lower level native code.
  PlayerEngineController? _engine;

  ///Controls configuration
  late PlayerControlsConfiguration _betterPlayerControlsConfiguration;

  ///Currently used data source in player.
  PlayerDataSource? _betterPlayerDataSource;

  ///Currently used translations
  PlayerTranslations translations = PlayerTranslations();

  ///List of event listeners, which listen to events.
  final List<Function(PlayerEvent)?> _eventListeners = [];

  ///List of callbacks for video player changes
  final List<VoidCallback> _videoListeners = [];

  ///List of files to delete once player disposes.
  final List<File> _tempFiles = [];

  /// Stream controller for controls visibility changes
  final StreamController<bool> _controlsVisibilityStreamController =
      StreamController.broadcast();

  /// Stream controller for next video time in playlist
  final StreamController<int?> _nextVideoTimeStreamController =
      StreamController.broadcast();

  /// Stream controller for internal controller events
  final StreamController<PlayerControllerEvent>
  _controllerEventStreamController = StreamController.broadcast();

  /// Subscription to video events from engine
  StreamSubscription<VideoEvent>? _videoEventStreamSubscription;

  /// Is player in full screen
  bool _isFullScreen = false;

  /// Last position selection timestamp
  int _lastPositionSelection = 0;

  /// List of subtitle sources
  final List<PlayerSubtitlesSource> _betterPlayerSubtitlesSourceList = [];

  /// Currently selected subtitle source
  PlayerSubtitlesSource? _betterPlayerSubtitlesSource;

  /// Lines of currently active subtitles
  List<PlayerSubtitle> subtitlesLines = [];

  /// Currently rendered subtitle
  PlayerSubtitle? renderedSubtitle;

  /// Available ASMS tracks
  List<PlayerAsmsTrack> _betterPlayerAsmsTracks = [];

  /// Currently selected ASMS track
  PlayerAsmsTrack? _betterPlayerAsmsTrack;

  /// Available ASMS audio tracks
  List<PlayerAsmsAudioTrack> _betterPlayerAsmsAudioTracks = [];

  /// Currently selected ASMS audio track
  PlayerAsmsAudioTrack? _betterPlayerAsmsAudioTrack;

  /// Timer for next video in playlist
  Timer? _nextVideoTimer;

  /// Time remaining for next video in playlist
  int? _nextVideoTime;

  /// Is controller disposed
  bool _disposed = false;

  /// Was playing before pause
  bool? _wasPlayingBeforePause;

  /// Has data source started playing
  bool _hasCurrentDataSourceStarted = false;

  /// Has data source initialized
  bool _hasCurrentDataSourceInitialized = false;

  /// Current app lifecycle state
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  /// Are controls enabled
  bool _controlsEnabled = true;

  /// Overridden aspect ratio
  double? _overriddenAspectRatio;

  /// Overridden box fit
  BoxFit? _overriddenFit;

  /// Was in PIP mode
  bool _wasInPipMode = false;

  /// Was in full screen before PIP
  bool _wasInFullScreenBeforePiP = false;

  /// Were controls enabled before PIP
  bool _wasControlsEnabledBeforePiP = false;

  /// Global key for player
  GlobalKey? _betterPlayerGlobalKey;

  /// Are controls always visible
  bool _controlsAlwaysVisible = false;

  /// Video player value on error
  VideoPlayerValue? _videoPlayerValueOnError;

  /// Is player visible
  bool _isPlayerVisible = true;

  /// Are ASMS segments loading
  bool _asmsSegmentsLoading = false;

  /// Loaded ASMS segments
  final List<String> _asmsSegmentsLoaded = [];

  /// Construct BetterPlayerController
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

  /// Get current controls configuration
  PlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _betterPlayerControlsConfiguration;

  ///Expose all active eventListeners
  List<Function(PlayerEvent)?> get eventListeners => _eventListeners.sublist(1);

  /// Defines a event listener where video player events will be send.
  Function(PlayerEvent)? get eventListener =>
      betterPlayerConfiguration.eventListener;

  /// Is currently in full screen
  bool get isFullScreen => _isFullScreen;

  /// Current data source
  PlayerDataSource? get betterPlayerDataSource => _betterPlayerDataSource;

  /// List of subtitle sources
  List<PlayerSubtitlesSource> get betterPlayerSubtitlesSourceList =>
      _betterPlayerSubtitlesSourceList;

  /// Current subtitle source
  PlayerSubtitlesSource? get betterPlayerSubtitlesSource =>
      _betterPlayerSubtitlesSource;

  /// Available ASMS tracks
  List<PlayerAsmsTrack> get betterPlayerAsmsTracks => _betterPlayerAsmsTracks;

  /// Current ASMS track
  PlayerAsmsTrack? get betterPlayerAsmsTrack => _betterPlayerAsmsTrack;

  /// Available ASMS audio tracks
  List<PlayerAsmsAudioTrack> get betterPlayerAsmsAudioTracks =>
      _betterPlayerAsmsAudioTracks;

  /// Current ASMS audio track
  PlayerAsmsAudioTrack? get betterPlayerAsmsAudioTrack =>
      _betterPlayerAsmsAudioTrack;

  /// Stream of next video time in playlist
  Stream<int?> get nextVideoTimeStream => _nextVideoTimeStreamController.stream;

  /// Stream of controls visibility changes
  Stream<bool> get controlsVisibilityStream =>
      _controlsVisibilityStreamController.stream;

  /// Stream of internal controller events
  Stream<PlayerControllerEvent> get controllerEventStream =>
      _controllerEventStreamController.stream;

  /// Are controls enabled
  bool get controlsEnabled => _controlsEnabled;

  /// Global key for player
  GlobalKey? get betterPlayerGlobalKey => _betterPlayerGlobalKey;

  /// Are controls always visible
  bool get controlsAlwaysVisible => _controlsAlwaysVisible;

  /// Has data source started
  bool get hasCurrentDataSourceStarted => _hasCurrentDataSourceStarted;

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

  /// Get current video player value (state).
  VideoPlayerValue? get videoPlayerValue => _engine?.value;

  /// Current playback position.
  Future<Duration?> get position async => _engine?.position;

  /// Absolute position in a live stream (EXT-X-PROGRAM-DATE-TIME).
  Future<DateTime?> get absolutePosition async => _engine?.absolutePosition;

  ///Get BetterPlayerController from context. Used in InheritedWidget.
  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>()!;

    return betterPLayerControllerProvider.controller;
  }

  /// Add listener for video player state changes.
  void addVideoListener(VoidCallback listener) {
    _videoListeners.add(listener);
  }

  /// Remove listener for video player state changes.
  void removeVideoListener(VoidCallback listener) {
    _videoListeners.remove(listener);
  }

  /// Build the internal VideoPlayer view.
  Widget buildVideoPlayerView() {
    if (_engine == null) {
      return const SizedBox();
    }
    return PlayerEngineView(_engine);
  }

  /// Sets the new [betterPlayerControlsConfiguration] instance in the
  /// controller.
  void setPlayerControlsConfiguration(
    PlayerControlsConfiguration betterPlayerControlsConfiguration,
  ) {
    _betterPlayerControlsConfiguration = betterPlayerControlsConfiguration;
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
