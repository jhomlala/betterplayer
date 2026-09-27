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
  SemanticsBinding.instance.ensureSemantics();
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
  String? _errorDescription;
  bool _runtimeConfigUpdated = false;
  bool _visibilityCallbackFired = false;
  bool _allCoreEventsVerified = false;
  bool _usingAlternateTheme = false;
  bool _isPlaylistMode = false;
  bool _playlistVerified = false;
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
    _betterPlayerController.setPlayerControlsConfiguration(
      const PlayerControlsConfiguration(
        controlsHideTime: Duration(days: 30),
        progressBarPlayedColor: Colors.green,
      ),
    );
    setState(() {
      _runtimeConfigUpdated = true;
    });
  }

  void _toggleAlternateControlsTheme() {
    setState(() {
      _usingAlternateTheme = !_usingAlternateTheme;
    });
    final PlayerTheme targetTheme;
    if (_usingAlternateTheme) {
      targetTheme = (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
          ? PlayerTheme.material
          : PlayerTheme.cupertino;
    } else {
      targetTheme = kIsWeb
          ? PlayerTheme.web
          : (defaultTargetPlatform == TargetPlatform.iOS
                ? PlayerTheme.cupertino
                : PlayerTheme.material);
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
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlistController =
          _playlistKey.currentState?.betterPlayerPlaylistController;
      if (playlistController == null) {
        return;
      }
      var changedPlaylistFired = false;
      playlistController.betterPlayerController?.addEventsListener((event) {
        if (event.betterPlayerEventType ==
            PlayerEventType.changedPlaylistItem) {
          changedPlaylistFired = true;
        }
      });
      playlistController.playNextVideo();
      final movedToSecond = playlistController.currentDataSourceIndex == 1;
      if (movedToSecond && changedPlaylistFired && mounted) {
        setState(() {
          _playlistVerified = true;
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
            const SizedBox(height: 200),
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
