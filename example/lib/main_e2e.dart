import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as m3;
void main() {
  BetterPlayerUtils.log('E2E: Starting main()');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BetterPlayerE2EApp());
}

class BetterPlayerE2EApp extends StatelessWidget {
  const BetterPlayerE2EApp({super.key});

  @override
  Widget build(BuildContext context) {
    BetterPlayerUtils.log('E2E: Building BetterPlayerE2EApp');
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
    BetterPlayerUtils.log('E2E: initState starting');
    super.initState();
    const betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: true,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ],
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      BetterPlayerUtils.log('E2E: postFrameCallback - setting up data source');
      final betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        Constants.bugBuckBunnyVideoUrl,
      );
      _betterPlayerController.setupDataSource(betterPlayerDataSource);
      _betterPlayerController.setControlsAlwaysVisible(true);
    });

    _betterPlayerController.addEventsListener((event) {
      BetterPlayerUtils.log(
        'E2E: Event received: ${event.betterPlayerEventType}',
      );
      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        BetterPlayerUtils.log('E2E: Exception event: ${event.parameters}');
        setState(() {
          _errorDescription = _betterPlayerController
              .videoPlayerController
              ?.value
              .errorDescription;
        });
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.setupDataSource) {
        BetterPlayerUtils.log('E2E: setupDataSource event');
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
    BetterPlayerDataSourceType type, {
    BetterPlayerDrmConfiguration? drmConfiguration,
  }) {
    final betterPlayerDataSource = BetterPlayerDataSource(
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
    BetterPlayerUtils.log('E2E: E2EPlayerPage build()');
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'better_player_e2e_app_bar_title',
          child: const Text('Better Player Example'),
        ),
      ),
      body: Column(
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
                        'Status: Init: ${_betterPlayerController.videoPlayerController?.value.initialized}, '
                        'Buffering: ${_betterPlayerController.videoPlayerController?.value.isBuffering}, '
                        'Playing: ${_betterPlayerController.videoPlayerController?.value.isPlaying}',
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
                    BetterPlayerDataSourceType.network,
                  ),
                  child: const Text('MP4'),
                ),
              ),
              Semantics(
                identifier: 'better_player_e2e_setup_hls',
                child: ElevatedButton(
                  onPressed: () => _setupDataSource(
                    Constants.hlsTestStreamUrl,
                    BetterPlayerDataSourceType.network,
                  ),
                  child: const Text('HLS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
