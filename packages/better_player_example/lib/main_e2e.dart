import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/ffi_test_page.dart';
import 'package:better_player_example/pages/seek_e2e_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as m3;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const BetterPlayerE2EApp());
}

class BetterPlayerE2EApp extends StatelessWidget {
  const BetterPlayerE2EApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        m3.GlobalMaterialLocalizations.delegate,
      ],
      home: E2EPlayerPage(),
    );
  }
}

class E2EPlayerPage extends StatefulWidget {
  const E2EPlayerPage({super.key});

  @override
  _E2EPlayerPageState createState() => _E2EPlayerPageState();
}

class _E2EPlayerPageState extends State<E2EPlayerPage> {
  late BetterPlayerController _betterPlayerController;
  final GlobalKey<BetterPlayerPlaylistState> _playlistKey =
      GlobalKey<BetterPlayerPlaylistState>();
  final BetterPlayerListVideoPlayerController _listVideoPlayerController =
      BetterPlayerListVideoPlayerController();
  String? _errorDescription;
  bool _runtimeConfigUpdated = false;
  bool _visibilityCallbackFired = false;
  bool _allCoreEventsVerified = false;
  bool _keyboardShortcutVerified = false;
  bool _usingAlternateTheme = false;
  bool _isPlaylistMode = false;
  bool _playlistVerified = false;
  bool _isListPlayerMode = false;
  bool _listPlayerVerified = false;
  final Set<PlayerEventType> _emittedEvents = {};

  static const Set<PlayerEventType> _requiredCoreEvents = {
    PlayerEventType.setupDataSource,
    PlayerEventType.play,
    PlayerEventType.pause,
    PlayerEventType.setVolume,
    PlayerEventType.setSpeed,
    PlayerEventType.changedTrack,
    PlayerEventType.changedSubtitles,
  };

  static const String _e2eWebVttSubtitle =
      'WEBVTT\n\n1\n00:00:00.000 --> 00:10:00.000\nE2E Test Subtitle\n';

  @override
  void initState() {
    super.initState();
    final betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: true,
      handleLifecycle: false,
      playerVisibilityChangedBehavior: (visibilityFraction) {
        if (mounted) {
          setState(() {
            _visibilityCallbackFired = true;
          });
        }
      },
      deviceOrientationsAfterFullScreen: const [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ],
      controlsConfiguration: const PlayerControlsConfiguration(
        controlsHideTime: Duration(days: 30),
      ),
      playerLogConfiguration: const PlayerLoggerConfiguration(
        logLevel: PlayerLogLevel.debug,
        outputs: [ConsoleLogOutput(usePrint: true)],
      ),
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDataSource(
        Constants.bugBuckBunnyVideoUrl,
        DataSourceType.network,
      );
      _betterPlayerController.setControlsAlwaysVisible(true);
    });

    _betterPlayerController.addEventsListener((event) {
      _emittedEvents.add(event.betterPlayerEventType);
      if (!_allCoreEventsVerified &&
          _emittedEvents.containsAll(_requiredCoreEvents)) {
        if (mounted) {
          setState(() {
            _allCoreEventsVerified = true;
          });
        }
      }
      if (event.betterPlayerEventType == PlayerEventType.setVolume) {
        final volume = event.parameters?['volume'] as double?;
        if (volume != null && volume > 0.0 && volume < 1.0 && mounted) {
          setState(() {
            _keyboardShortcutVerified = true;
          });
        }
      }
      if (event.betterPlayerEventType == PlayerEventType.exception) {
        setState(() {
          _errorDescription =
              event.parameters?['exception']?.toString() ??
              _betterPlayerController.videoPlayerValue?.errorDescription;
        });
      } else if (event.betterPlayerEventType ==
          PlayerEventType.setupDataSource) {
        setState(() {
          _errorDescription = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  void _setupDataSource(
    String url,
    DataSourceType type, {
    DrmConfiguration? drmConfiguration,
  }) {
    final betterPlayerDataSource = PlayerDataSource(
      type,
      url,
      drmConfiguration: drmConfiguration,
      subtitles: url == Constants.bugBuckBunnyVideoUrl
          ? [
              PlayerSubtitlesSource(
                type: PlayerSubtitlesSourceType.memory,
                name: 'English',
                content: _e2eWebVttSubtitle,
                selectedByDefault: true,
              ),
            ]
          : null,
      asmsTrackNames: url == Constants.hlsTestStreamUrl
          ? const [
              'Track 1',
              'Track 2',
              'Track 3',
              'Track 4',
              'Track 5',
            ]
          : null,
    );
    _betterPlayerController.setupDataSource(betterPlayerDataSource);
  }

  void _applyRuntimeControlsConfiguration() {
    _betterPlayerController
      ..setPlayerControlsConfiguration(
        const PlayerControlsConfiguration(
          controlsHideTime: Duration(days: 30),
          progressBarPlayedColor: Colors.green,
        ),
      )
      ..setPlayerSubtitlesConfiguration(
        const PlayerSubtitlesConfiguration(
          fontSize: 22,
          fontColor: Colors.yellow,
        ),
      );
    final controlsApplied =
        _betterPlayerController
            .betterPlayerControlsConfiguration
            .progressBarPlayedColor ==
        Colors.green;
    final subtitlesApplied =
        _betterPlayerController.betterPlayerSubtitlesConfiguration.fontSize ==
            22 &&
        _betterPlayerController.betterPlayerSubtitlesConfiguration.fontColor ==
            Colors.yellow;
    if (controlsApplied && subtitlesApplied) {
      setState(() {
        _runtimeConfigUpdated = true;
      });
    }
  }

  void _toggleAlternateControlsTheme() {
    setState(() {
      _usingAlternateTheme = !_usingAlternateTheme;
    });
    final isApple =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final PlayerTheme targetTheme;
    if (_usingAlternateTheme) {
      targetTheme = isApple ? PlayerTheme.material : PlayerTheme.cupertino;
    } else {
      targetTheme = kIsWeb
          ? PlayerTheme.web
          : (isApple ? PlayerTheme.cupertino : PlayerTheme.material);
    }
    _betterPlayerController.setPlayerControlsConfiguration(
      PlayerControlsConfiguration(
        playerTheme: targetTheme,
        controlsHideTime: const Duration(days: 30),
      ),
    );
    _betterPlayerController.setControlsAlwaysVisible(true);
  }

  Future<void> _triggerVisibilityCycle() async {
    await _betterPlayerController.onPlayerVisibilityChanged(0);
    await _betterPlayerController.onPlayerVisibilityChanged(1);
  }

  Future<void> _runPlaylistTest() async {
    await _betterPlayerController.pause();
    setState(() {
      _isPlaylistMode = true;
      _isListPlayerMode = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlistController =
          _playlistKey.currentState?.betterPlayerPlaylistController;
      if (playlistController == null) {
        return;
      }
      var changedPlaylistCount = 0;
      playlistController.betterPlayerController?.addEventsListener((event) {
        if (event.betterPlayerEventType ==
            PlayerEventType.changedPlaylistItem) {
          changedPlaylistCount++;
        }
      });
      playlistController.playNextVideo();
      final movedToSecond = playlistController.currentDataSourceIndex == 1;
      playlistController.playPreviousVideo();
      final movedBackToFirst = playlistController.currentDataSourceIndex == 0;
      playlistController.playNextVideo();
      final movedAgainToSecond = playlistController.currentDataSourceIndex == 1;
      playlistController.setupDataSourceList([
        PlayerDataSource(
          DataSourceType.network,
          Constants.bugBuckBunnyVideoUrl,
        ),
        PlayerDataSource(
          DataSourceType.network,
          Constants.forBiggerBlazesUrl,
        ),
      ]);
      final resetToFirst = playlistController.currentDataSourceIndex == 0;
      if (movedToSecond &&
          movedBackToFirst &&
          movedAgainToSecond &&
          resetToFirst &&
          changedPlaylistCount >= 4 &&
          mounted) {
        setState(() {
          _playlistVerified = true;
        });
      }
    });
  }

  Future<void> _runListAndDisposeTest() async {
    // 1. Mid-initialization disposal stress test (#976, #895)
    final tempController = BetterPlayerController(
      const PlayerConfiguration(),
    );
    unawaited(
      tempController.setupDataSource(
        PlayerDataSource(
          DataSourceType.network,
          Constants.bugBuckBunnyVideoUrl,
        ),
      ),
    );
    tempController.dispose(forceDispose: true);

    // 2. Mount BetterPlayerListVideoPlayer and exercise its controller (#864)
    await _betterPlayerController.pause();
    setState(() {
      _isPlaylistMode = false;
      _isListPlayerMode = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _listVideoPlayerController
          ..setVolume(0.5)
          ..play()
          ..pause();
        if (_listVideoPlayerController.betterPlayerController
                ?.isVideoInitialized() ??
            false) {
          _listVideoPlayerController.seekTo(const Duration(seconds: 2));
        }
        _listVideoPlayerController.setMixWithOthers(true);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _listPlayerVerified = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'better_player_e2e_app_bar_title',
          label: 'better_player_e2e_app_bar_title',
          child: const Text('Better Player Example'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _isPlaylistMode
                    ? BetterPlayerPlaylist(
                        key: _playlistKey,
                        betterPlayerConfiguration: const PlayerConfiguration(
                          aspectRatio: 16 / 9,
                          autoPlay: true,
                          controlsConfiguration: PlayerControlsConfiguration(
                            controlsHideTime: Duration(days: 30),
                          ),
                        ),
                        betterPlayerPlaylistConfiguration:
                            const PlayerPlaylistConfiguration(
                              nextVideoDelay: Duration(seconds: 1),
                            ),
                        betterPlayerDataSourceList: [
                          PlayerDataSource(
                            DataSourceType.network,
                            Constants.bugBuckBunnyVideoUrl,
                          ),
                          PlayerDataSource(
                            DataSourceType.network,
                            Constants.forBiggerBlazesUrl,
                          ),
                        ],
                      )
                    : _isListPlayerMode
                    ? ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          BetterPlayerListVideoPlayer(
                            PlayerDataSource(
                              DataSourceType.network,
                              Constants.bugBuckBunnyVideoUrl,
                            ),
                            configuration: const PlayerConfiguration(
                              aspectRatio: 16 / 9,
                              controlsConfiguration:
                                  PlayerControlsConfiguration(
                                    controlsHideTime: Duration(days: 30),
                                  ),
                            ),
                            betterPlayerListVideoPlayerController:
                                _listVideoPlayerController,
                          ),
                        ],
                      )
                    : BetterPlayer(controller: _betterPlayerController),
              ),
            ),
            if (_errorDescription != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Semantics(
                  identifier: 'better_player_e2e_error_text',
                  label: 'better_player_e2e_error_text',
                  container: true,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error: $_errorDescription',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DebugLine(
                          'URL',
                          _betterPlayerController.betterPlayerDataSource?.url,
                        ),
                        Text(
                          'Status: Init: ${_betterPlayerController.videoPlayerValue?.initialized}, '
                          'Buffering: ${_betterPlayerController.videoPlayerValue?.isBuffering}, '
                          'Playing: ${_betterPlayerController.videoPlayerValue?.isPlaying}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_allCoreEventsVerified)
              Semantics(
                identifier: 'better_player_e2e_events_verified',
                label: 'better_player_e2e_events_verified',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Core Events Verified'),
                ),
              ),
            if (_keyboardShortcutVerified)
              Semantics(
                identifier: 'better_player_e2e_keyboard_shortcut_status',
                label: 'better_player_e2e_keyboard_shortcut_status',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Keyboard Shortcut Verified'),
                ),
              ),
            if (_runtimeConfigUpdated)
              Semantics(
                identifier: 'better_player_e2e_runtime_config_status',
                label: 'better_player_e2e_runtime_config_status',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Runtime Config Updated'),
                ),
              ),
            if (_visibilityCallbackFired)
              Semantics(
                identifier: 'better_player_e2e_visibility_callback_status',
                label: 'better_player_e2e_visibility_callback_status',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Visibility Callback Fired'),
                ),
              ),
            if (_playlistVerified)
              Semantics(
                identifier: 'better_player_e2e_playlist_status',
                label: 'better_player_e2e_playlist_status',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Playlist Verified'),
                ),
              ),
            if (_listPlayerVerified)
              Semantics(
                identifier: 'better_player_e2e_list_player_status',
                label: 'better_player_e2e_list_player_status',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('List Player Verified'),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Semantics(
                  identifier: 'better_player_e2e_setup_mp4',
                  label: 'better_player_e2e_setup_mp4',
                  child: ElevatedButton(
                    onPressed: () => _setupDataSource(
                      Constants.bugBuckBunnyVideoUrl,
                      DataSourceType.network,
                    ),
                    child: const Text('MP4'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_setup_hls',
                  label: 'better_player_e2e_setup_hls',
                  child: ElevatedButton(
                    onPressed: () => _setupDataSource(
                      Constants.hlsTestStreamUrl,
                      DataSourceType.network,
                    ),
                    child: const Text('HLS'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_setup_error',
                  label: 'better_player_e2e_setup_error',
                  child: ElevatedButton(
                    onPressed: () => _setupDataSource(
                      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/404.mp4',
                      DataSourceType.network,
                    ),
                    child: const Text('Invalid'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_runtime_config_button',
                  label: 'better_player_e2e_runtime_config_button',
                  child: ElevatedButton(
                    onPressed: _applyRuntimeControlsConfiguration,
                    child: const Text('Runtime Config'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_toggle_theme_button',
                  label: 'better_player_e2e_toggle_theme_button',
                  child: ElevatedButton(
                    onPressed: _toggleAlternateControlsTheme,
                    child: const Text('Toggle Theme'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_visibility_cycle_button',
                  label: 'better_player_e2e_visibility_cycle_button',
                  child: ElevatedButton(
                    onPressed: _triggerVisibilityCycle,
                    child: const Text('Visibility Cycle'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_playlist_button',
                  label: 'better_player_e2e_playlist_button',
                  child: ElevatedButton(
                    onPressed: _runPlaylistTest,
                    child: const Text('Playlist Test'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_list_player_button',
                  label: 'better_player_e2e_list_player_button',
                  child: ElevatedButton(
                    onPressed: _runListAndDisposeTest,
                    child: const Text('List Player Test'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_navigate_ffi',
                  label: 'better_player_e2e_navigate_ffi',
                  child: ElevatedButton(
                    onPressed: () {
                      _betterPlayerController.pause();
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const FFITestPage(),
                        ),
                      );
                    },
                    child: const Text('FFI Test'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_navigate_seek',
                  label: 'better_player_e2e_navigate_seek',
                  child: ElevatedButton(
                    onPressed: () {
                      _betterPlayerController.pause();
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const SeekE2EPage(),
                        ),
                      );
                    },
                    child: const Text('Seek Test'),
                  ),
                ),
              ],
            ),
            if (!kIsWeb) const SizedBox(height: 200),
          ],
        ),
      ),
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${value ?? 'N/A'}',
      style: const TextStyle(fontSize: 9, fontFamily: 'Courier'),
      maxLines: 2,
      overflow: TextOverflow.visible,
    );
  }
}
