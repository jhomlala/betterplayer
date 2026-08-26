import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:material_ui/material_ui.dart';

class AutoFullscreenOrientationPage extends StatefulWidget {
  const AutoFullscreenOrientationPage({super.key});

  @override
  _AutoFullscreenOrientationPageState createState() =>
      _AutoFullscreenOrientationPageState();
}

class _AutoFullscreenOrientationPageState
    extends State<AutoFullscreenOrientationPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoDetectFullscreenDeviceOrientation: true,
    );
    final dataSource = BetterPlayerDataSource(
      DataSourceType.network,
      Constants.forBiggerBlazesUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto full screen orientation')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Aspect ratio and device orientation on full screen will be '
                'managed by the BetterPlayer. Click on the fullscreen option.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController),
            ),
            ElevatedButton(
              child: const Text('Play horizontal video'),
              onPressed: () async {
                final dataSource = BetterPlayerDataSource(
                  DataSourceType.network,
                  Constants.forBiggerBlazesUrl,
                );
                await _betterPlayerController.setupDataSource(dataSource);
                _betterPlayerController.enterFullScreen();
              },
            ),
            ElevatedButton(
              child: const Text('Play vertical video'),
              onPressed: () async {
                final dataSource = BetterPlayerDataSource(
                  DataSourceType.network,
                  Constants.verticalVideoUrl,
                );
                await _betterPlayerController.setupDataSource(dataSource);
                _betterPlayerController.enterFullScreen();
              },
            ),
          ],
        ),
      ),
    );
  }
}
