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

/// Class used to control overall Better Player behavior. Main class to change
/// state of Better Player and orchestrate its subsystems (subtitles, caching, analytics, etc).
class BetterPlayerController {
  /// Parameter key used to pass the duration of the media in player events.
  /// Typically passed within a Map of event parameters.
  static const String _durationParameter = 'duration';

  /// Parameter key used to pass the current playback progress of the media.
  /// Typically passed within a Map of event parameters alongside duration.
  static const String _progressParameter = 'progress';

  /// Parameter key used to indicate the buffered ranges of the media stream.
  /// Helps UI components render the buffered progress bar.
  static const String _bufferedParameter = 'buffered';

  /// Parameter key used to communicate changes in audio volume.
  static const String _volumeParameter = 'volume';

  /// Parameter key used to communicate changes in playback speed (e.g. 1.0x, 2.0x).
  static const String _speedParameter = 'speed';

  /// Parameter key used to attach the currently loaded [PlayerDataSource] to an event.
  static const String _dataSourceParameter = 'dataSource';

  /// HTTP Header key used specifically for DRM authentication tokens.
  static const String _authorizationHeader = 'Authorization';

  /// General configuration used to initialize this controller instance.
  /// This dictates UI properties, error handling, layout behaviors, and overall player traits.
  final PlayerConfiguration betterPlayerConfiguration;

  /// Playlist configuration used in controller instance.
  /// Only applicable if the player is set up to handle a playlist of videos,
  /// dictating auto-advance behavior, looping, and playlist-specific UI.
  final PlayerPlaylistConfiguration? betterPlayerPlaylistConfiguration;

  /// Instance of the internal video player controller engine.
  /// Acts as the primary adapter used to communicate between Flutter's high-level code
  /// and the lower-level native Android/iOS platform code.
  PlayerEngineController? _engine;

  /// Defines the visual and behavioral configuration for the player's controls.
  /// Used to customize colors, icons, padding, and interactive behaviors of the UI overlay.
  late PlayerControlsConfiguration _betterPlayerControlsConfiguration;

  /// The data source currently loaded into the player.
  /// Defines the video URL, format (HLS, DASH, MP4), headers, DRM, and resolution.
  PlayerDataSource? _betterPlayerDataSource;

  /// The set of translations used to localize the player's controls and error messages.
  /// Defaults to a base set of standard translations if not customized.
  PlayerTranslations translations = PlayerTranslations();

  /// List of active event listeners that have subscribed to the player's event stream.
  /// Listeners will receive real-time updates for state changes, buffering, and user interactions.
  final List<Function(PlayerEvent)?> _eventListeners = [];

  /// List of internal callbacks for low-level video player changes.
  /// Triggers whenever the internal engine reports a state change (initialization, buffering, completion).
  final List<VoidCallback> _videoListeners = [];

  /// List of temporary files created during playback (e.g. cached files or subtitles)
  /// that are scheduled to be deleted once the player disposes, to prevent storage leaks.
  final List<File> _tempFiles = [];

  /// Broadcast stream controller used to notify the UI when the player's control overlay
  /// becomes visible or hidden. Helps coordinate animations and PIP state.
  final StreamController<bool> _controlsVisibilityStreamController =
      StreamController.broadcast();

  /// Broadcast stream controller used to emit the countdown time remaining
  /// before the next video in a playlist begins. Used by playlist UI components.
  final StreamController<int?> _nextVideoTimeStreamController =
      StreamController.broadcast();

  /// Broadcast stream controller used internally for structural controller events
  /// (e.g. when a new data source is set, or a critical error occurs).
  final StreamController<PlayerControllerEvent>
  _controllerEventStreamController = StreamController.broadcast();

  /// Holds the active subscription to the video engine's raw event stream.
  /// Listens to low-level native events and forwards them to the controller's listeners.
  StreamSubscription<VideoEvent>? _videoEventStreamSubscription;

  /// Flag indicating whether the player is currently taking up the entire screen.
  /// Managed by full-screen specific methods and controls UI overlay scaling.
  bool _isFullScreen = false;

  /// Epoch timestamp of the last time a progress event was emitted.
  /// Used to throttle progress updates to prevent overwhelming the UI thread.
  int _lastPositionSelection = 0;

  /// Complete list of all available subtitle sources for the current media.
  /// Can include side-loaded VTT/SRT files or embedded streams.
  final List<PlayerSubtitlesSource> _betterPlayerSubtitlesSourceList = [];

  /// The specific subtitle source currently active and being parsed.
  /// Null if subtitles are disabled or unavailable.
  PlayerSubtitlesSource? _betterPlayerSubtitlesSource;

  /// The parsed list of subtitle lines (start time, end time, text content)
  /// for the currently active subtitle source.
  List<PlayerSubtitle> subtitlesLines = [];

  /// The exact subtitle line that should currently be rendered on the screen
  /// based on the video's current playback position.
  PlayerSubtitle? renderedSubtitle;

  /// Complete list of video quality tracks parsed from ASMS (HLS/DASH) manifests.
  /// Allows the user or system to switch between different resolutions/bitrates.
  List<PlayerAsmsTrack> _betterPlayerAsmsTracks = [];

  /// The specific ASMS (HLS/DASH) video track currently selected for playback.
  /// If null, the player is typically relying on automatic adaptive bitrate streaming.
  PlayerAsmsTrack? _betterPlayerAsmsTrack;

  /// Complete list of alternative audio tracks parsed from ASMS (HLS/DASH) manifests.
  /// Useful for multi-language videos or descriptive audio streams.
  List<PlayerAsmsAudioTrack> _betterPlayerAsmsAudioTracks = [];

  /// The specific ASMS (HLS/DASH) audio track currently selected for playback.
  PlayerAsmsAudioTrack? _betterPlayerAsmsAudioTrack;

  /// Timer managing the countdown delay before the next video in a playlist automatically starts.
  Timer? _nextVideoTimer;

  /// The remaining time in seconds before the next video in the playlist starts.
  int? _nextVideoTime;

  /// Flag indicating whether this controller has been disposed.
  /// Used as a safeguard to prevent method calls or stream emissions after teardown.
  bool _disposed = false;

  /// Tracks the play/pause state right before a systemic pause occurred
  /// (e.g. entering PIP, app backgrounding) so it can be restored appropriately.
  bool? _wasPlayingBeforePause;

  /// Flag indicating whether the current data source has begun playback at least once.
  bool _hasCurrentDataSourceStarted = false;

  /// Flag indicating whether the internal engine has successfully parsed the
  /// current data source and initialized its duration and dimensions.
  bool _hasCurrentDataSourceInitialized = false;

  /// Tracks the lifecycle state of the Flutter application.
  /// Used to automatically pause/resume video playback when the app goes into the background.
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  /// Flag indicating whether the interactive UI controls (play/pause, timeline) are enabled.
  /// If false, the controls are disabled and potentially hidden.
  bool _controlsEnabled = true;

  /// A specific aspect ratio that overrides the configuration's aspect ratio.
  /// Can be used to force the player into a specific shape regardless of video dimensions.
  double? _overriddenAspectRatio;

  /// A specific Box Fit mode that overrides the configuration's fit.
  /// Controls how the video scales within its bounds (e.g. cover, contain).
  BoxFit? _overriddenFit;

  /// Flag indicating whether the player was recently placed into Picture-in-Picture mode.
  bool _wasInPipMode = false;

  /// Stores the full screen state prior to entering Picture-in-Picture mode.
  /// Used to accurately restore the player's state when exiting PIP.
  bool _wasInFullScreenBeforePiP = false;

  /// Stores the controls enablement state prior to entering Picture-in-Picture mode.
  /// Controls are typically disabled in PIP, and this ensures they are re-enabled correctly.
  bool _wasControlsEnabledBeforePiP = false;

  /// A globally unique key representing the BetterPlayer widget instance in the widget tree.
  /// Can be used to access the widget's context or force a rebuild.
  GlobalKey? _betterPlayerGlobalKey;

  /// Flag indicating whether the controls overlay should remain persistently visible,
  /// ignoring standard auto-hide timers.
  bool _controlsAlwaysVisible = false;

  /// Stores the last valid video player state exactly when a critical error occurred.
  /// Useful for diagnostics or attempting to resume playback from the failure point.
  VideoPlayerValue? _videoPlayerValueOnError;

  /// Flag indicating whether the player surface is currently visible on the screen.
  bool _isPlayerVisible = true;

  /// Flag indicating whether ASMS (HLS/DASH) segments are currently being downloaded/parsed.
  bool _asmsSegmentsLoading = false;

  /// A record of successfully loaded ASMS segment identifiers to prevent redundant network calls.
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
