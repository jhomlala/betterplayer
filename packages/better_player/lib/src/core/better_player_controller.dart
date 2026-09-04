import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:better_player/src/core/player_event_constants.dart';
import 'package:better_player/src/core/state/player_playback_state.dart';
import 'package:better_player/src/core/state/player_subtitle_state.dart';
import 'package:better_player/src/core/state/player_track_state.dart';
import 'package:better_player/src/core/state/player_view_state.dart';
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

  /// Timer managing the countdown delay before the next video in a playlist automatically starts.
  Timer? _nextVideoTimer;

  /// The remaining time in seconds before the next video in the playlist starts.
  int? _nextVideoTime;

  /// Flag indicating whether this controller has been disposed.
  /// Used as a safeguard to prevent method calls or stream emissions after teardown.
  bool _disposed = false;

  /// Tracks the visual state and UI configurations of the Better Player.
  final PlayerViewState _viewState = PlayerViewState();

  /// Tracks the subtitle configurations, parsing status, and rendered lines.
  final PlayerSubtitleState _subtitleState = PlayerSubtitleState();

  /// Tracks the audio and video tracks parsed from ASMS (HLS/DASH) manifests.
  final PlayerTrackState _trackState = PlayerTrackState();

  /// Tracks the low-level playback and lifecycle state of the media player.
  final PlayerPlaybackState _playbackState = PlayerPlaybackState();

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

  /// Retrieves the current configuration used for the player's UI controls.
  /// Allows external components to inspect how controls are structured (e.g., icons, colors, layout).
  PlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _betterPlayerControlsConfiguration;

  /// Exposes a read-only list of all currently active event listeners subscribed to the player.
  /// Used primarily for debugging or routing global event streams without modifying active subscriptions.
  List<Function(PlayerEvent)?> get eventListeners => _eventListeners.sublist(1);

  /// Retrieves the primary global event listener defined within the configuration.
  /// This listener receives every state change and interaction event emitted by the player.
  Function(PlayerEvent)? get eventListener =>
      betterPlayerConfiguration.eventListener;

  /// Returns true if the player is currently rendered in full screen mode, false otherwise.
  bool get isFullScreen => _viewState.isFullScreen;

  /// Returns the actively configured data source detailing the media URL, DRM, and format.
  /// Returns null if no data source has been established yet.
  PlayerDataSource? get betterPlayerDataSource => _betterPlayerDataSource;

  /// Retrieves the complete list of all initialized subtitle sources.
  /// Includes side-loaded subtitle files (like SRT/VTT) as well as any parsed from the stream manifest.
  List<PlayerSubtitlesSource> get betterPlayerSubtitlesSourceList =>
      _subtitleState.subtitlesSourceList;

  /// Retrieves the single subtitle source currently selected and active for on-screen rendering.
  PlayerSubtitlesSource? get betterPlayerSubtitlesSource =>
      _subtitleState.subtitlesSource;

  /// The parsed list of subtitle lines (start time, end time, text content)
  /// for the currently active subtitle source.
  List<PlayerSubtitle> get subtitlesLines => _subtitleState.subtitlesLines;
  set subtitlesLines(List<PlayerSubtitle> value) =>
      _subtitleState.subtitlesLines = value;

  /// The exact subtitle line that should currently be rendered on the screen
  /// based on the video's current playback position.
  PlayerSubtitle? get renderedSubtitle => _subtitleState.renderedSubtitle;
  set renderedSubtitle(PlayerSubtitle? value) =>
      _subtitleState.renderedSubtitle = value;

  /// Retrieves the complete list of alternative video tracks parsed from ASMS (HLS/DASH) streams.
  /// Useful for populating a quality selection menu.
  List<PlayerAsmsTrack> get betterPlayerAsmsTracks => _trackState.asmsTracks;

  /// Retrieves the specifically selected ASMS video track dictating current resolution and bitrate.
  /// Returns null if the player is utilizing automatic adaptive streaming.
  PlayerAsmsTrack? get betterPlayerAsmsTrack => _trackState.asmsTrack;

  /// Retrieves the complete list of alternative audio tracks parsed from ASMS (HLS/DASH) streams.
  /// Useful for populating a language or descriptive audio selection menu.
  List<PlayerAsmsAudioTrack> get betterPlayerAsmsAudioTracks =>
      _trackState.asmsAudioTracks;

  /// Retrieves the specifically selected ASMS audio track dictating the current audio language/feed.
  PlayerAsmsAudioTrack? get betterPlayerAsmsAudioTrack =>
      _trackState.asmsAudioTrack;

  /// A broadcast stream emitting the countdown time (in seconds) until the next video in a playlist starts.
  /// UI elements can listen to this stream to render a live countdown clock.
  Stream<int?> get nextVideoTimeStream => _nextVideoTimeStreamController.stream;

  /// A broadcast stream emitting true when the control overlay becomes visible, and false when it hides.
  /// Useful for coordinating surrounding UI elements or system overlays (like the status bar) with the player UI.
  Stream<bool> get controlsVisibilityStream =>
      _controlsVisibilityStreamController.stream;

  /// A broadcast stream used for deeply internal structural events (like data source swaps).
  /// General consumers should use [eventListener] instead of tapping into this stream.
  Stream<PlayerControllerEvent> get controllerEventStream =>
      _controllerEventStreamController.stream;

  /// Indicates whether the interactive controls (play/pause, seek bar) are enabled and permitted to be shown.
  bool get controlsEnabled => _viewState.controlsEnabled;

  /// Retrieves the unique GlobalKey assigned to this specific BetterPlayer instance.
  /// Helps coordinate deeply nested UI state changes tied to this controller.
  GlobalKey? get betterPlayerGlobalKey => _viewState.betterPlayerGlobalKey;

  /// Indicates whether the controls are forced to remain visible indefinitely, completely bypassing auto-hide timers.
  bool get controlsAlwaysVisible => _viewState.controlsAlwaysVisible;

  /// Returns true if the current data source has begun playback and is actively buffering or playing media.
  bool get hasCurrentDataSourceStarted =>
      _playbackState.hasCurrentDataSourceStarted;

  /// Retrieves the internal texture ID provided by the native platform for rendering the video surface.
  /// Returns null if the underlying video engine hasn't fully initialized the rendering surface yet.
  int? get textureId => _engine?.textureId;

  /// Returns true if the underlying video engine has been successfully allocated.
  /// Returns false if [setupDataSource] hasn't been called or the engine was explicitly disposed.
  bool get isEngineReady => _engine != null;

  /// Returns true if the video engine has successfully initialized the media stream, meaning its dimensions
  /// and total duration are now known and playback can reliably begin.
  bool get isInitialized => _engine?.value.initialized ?? false;

  /// Returns the total duration of the currently loaded media.
  /// Returns null if the video has not yet been initialized or if it's a live stream of unknown length.
  Duration? get duration => _engine?.value.duration;

  /// Retrieves a complete snapshot of the underlying video engine's state (playing, buffering, volume, duration).
  /// For isolated state checks, prefer using the dedicated granular getters like [isInitialized] or [duration].
  VideoPlayerValue? get playerValue => _engine?.value;

  /// An alias for [playerValue] providing a complete snapshot of the underlying video engine's state.
  VideoPlayerValue? get videoPlayerValue => _engine?.value;

  /// Asynchronously retrieves the exact current playback position from the internal engine.
  Future<Duration?> get position async => _engine?.position;

  /// Asynchronously retrieves the absolute physical time corresponding to the current playback position.
  /// Only applicable to live streams that embed EXT-X-PROGRAM-DATE-TIME tags.
  Future<DateTime?> get absolutePosition async => _engine?.absolutePosition;

  /// Safely retrieves the [BetterPlayerController] instance from the nearest
  /// [BetterPlayerControllerProvider] in the widget tree.
  /// Used predominantly by internal UI components to access state.
  static BetterPlayerController of(BuildContext context) {
    final betterPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<BetterPlayerControllerProvider>()!;

    return betterPLayerControllerProvider.controller;
  }

  /// Subscribes a listener to raw video player state changes.
  /// Listeners will be invoked continuously during playback (e.g., position updates).
  void addVideoListener(VoidCallback listener) {
    _videoListeners.add(listener);
  }

  /// Unsubscribes a previously registered listener from video player state changes.
  void removeVideoListener(VoidCallback listener) {
    _videoListeners.remove(listener);
  }

  /// Constructs the low-level [PlayerEngineView] widget that physically renders the video texture.
  /// Should be placed securely within the widget tree where the video is meant to appear.
  Widget buildVideoPlayerView() {
    if (_engine == null) {
      return const SizedBox();
    }
    return PlayerEngineView(_engine);
  }

  /// Hotswaps the active [PlayerControlsConfiguration] dictating UI behavior.
  /// Allows dynamically changing themes or control layouts during playback.
  void setPlayerControlsConfiguration(
    PlayerControlsConfiguration betterPlayerControlsConfiguration,
  ) {
    _betterPlayerControlsConfiguration = betterPlayerControlsConfiguration;
  }

  /// Internal callback invoked whenever the underlying video engine reports a state change.
  /// Responsible for syncing engine state (PIP, initialization, progress) to the high-level controller.
  Future<void> _onVideoPlayerChanged() async {
    for (final listener in List<VoidCallback>.from(_videoListeners)) {
      listener();
    }

    final currentVideoPlayerValue =
        _engine?.value ?? VideoPlayerValue(duration: const Duration());

    if (currentVideoPlayerValue.initialized &&
        !_playbackState.hasCurrentDataSourceInitialized) {
      PlayerLogger.info(
        message: 'Video player initialized',
        textureId: textureId,
      );
      _playbackState.hasCurrentDataSourceInitialized = true;
      _postEvent(PlayerEvent(PlayerEventType.initialized));
    }
    if (currentVideoPlayerValue.isPip) {
      _viewState.wasInPipMode = true;
    } else if (_viewState.wasInPipMode) {
      _postEvent(PlayerEvent(PlayerEventType.pipStop));
      _viewState.wasInPipMode = false;
      if (!_viewState.wasInFullScreenBeforePiP) {
        exitFullScreen();
      }
      if (_viewState.wasControlsEnabledBeforePiP) {
        setControlsEnabled(true);
      }
      _engine?.refresh();
    }

    if (_subtitleState.subtitlesSource?.asmsIsSegmented == true) {
      _loadAsmsSubtitlesSegments(currentVideoPlayerValue.position);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _playbackState.lastPositionSelection > 500) {
      _playbackState.lastPositionSelection = now;
      _postEvent(
        PlayerEvent(
          PlayerEventType.progress,
          parameters: <String, dynamic>{
            PlayerEventConstants.progressParameter:
                currentVideoPlayerValue.position,
            PlayerEventConstants.durationParameter:
                currentVideoPlayerValue.duration,
          },
        ),
      );
    }
  }

  /// Internal callback that routes native [VideoEvent]s (from platform channels)
  /// into the controller's high-level [PlayerEvent] stream.
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
              PlayerEventConstants.progressParameter: videoValue?.position,
              PlayerEventConstants.durationParameter: videoValue?.duration,
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
              PlayerEventConstants.bufferedParameter: event.buffered,
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

  /// Disposes of the [BetterPlayerController] and gracefully tears down all resources.
  /// If [forceDispose] is false, this will abort if [PlayerConfiguration.autoDispose] is false.
  /// Automatically clears listeners, stops the engine, closes streams, and deletes temp files.
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
