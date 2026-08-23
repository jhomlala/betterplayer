import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as m3;

void main() => runApp(const BetterPlayerE2EApp());

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
    const betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: true,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ],
      controlsConfiguration: BetterPlayerControlsConfiguration(
        playerTheme: BetterPlayerTheme.cupertino,
      ),
    );
    final betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(betterPlayerDataSource);
    _betterPlayerController.setControlsAlwaysVisible(true);
    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        setState(() {
          _errorDescription =
              _betterPlayerController.videoPlayerController?.value.errorDescription;
        });
      } else if (event.betterPlayerEventType == BetterPlayerEventType.setupDataSource) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Better Player Example')),
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
                child: Text(
                  'Error: $_errorDescription',
                  style: const TextStyle(color: Colors.red),
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
              Semantics(
                identifier: 'better_player_e2e_setup_drm',
                child: ElevatedButton(
                  onPressed: () => _setupDataSource(
                    Constants.fairplayHlsUrl,
                    BetterPlayerDataSourceType.network,
                    drmConfiguration: BetterPlayerDrmConfiguration(
                      drmType: BetterPlayerDrmType.fairplay,
                      licenseUrl: Constants.fairplayLicenseUrl,
                      certificateUrl: Constants.fairplayCertificateUrl,
                    ),
                  ),
                  child: const Text('DRM'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
