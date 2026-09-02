import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/ffi_test_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as m3;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  String? _errorDescription;

  @override
  void initState() {
    super.initState();
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: true,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ],
      playerLogConfiguration: PlayerLoggerConfiguration(
        logLevel: PlayerLogLevel.debug,
        outputs: [ConsoleLogOutput(usePrint: true)],
      ),
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final betterPlayerDataSource = PlayerDataSource(
        DataSourceType.network,
        Constants.bugBuckBunnyVideoUrl,
      );
      _betterPlayerController.setupDataSource(betterPlayerDataSource);
      _betterPlayerController.setControlsAlwaysVisible(true);
    });

    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == PlayerEventType.exception) {
        setState(() {
          _errorDescription =
              event.parameters?['exception']?.toString() ??
              _betterPlayerController
                  .videoPlayerValue?.errorDescription;
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
    );
    _betterPlayerController.setupDataSource(betterPlayerDataSource);
  }

  Widget _buildDebugLine(String label, String? value) {
    return Text(
      '$label: ${value ?? 'N/A'}',
      style: const TextStyle(fontSize: 9, fontFamily: 'Courier'),
      maxLines: 2,
      overflow: TextOverflow.visible,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'better_player_e2e_app_bar_title',
          child: const Text('Better Player Example'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController),
            ),
            if (_errorDescription != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Semantics(
                  identifier: 'better_player_e2e_error_text',
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
                        _buildDebugLine(
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Semantics(
                  identifier: 'better_player_e2e_setup_mp4',
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
                  child: ElevatedButton(
                    onPressed: () => _setupDataSource(
                      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/404.mp4',
                      DataSourceType.network,
                    ),
                    child: const Text('Invalid'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_navigate_ffi',
                  child: ElevatedButton(
                    onPressed: () {
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
              ],
            ),
            const SizedBox(height: 200),
          ],
        ),
      ),
    );
  }
}



