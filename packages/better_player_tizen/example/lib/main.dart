import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const BetterPlayerTizenExampleApp());
}

/// Main application widget for the Tizen Better Player example.
class BetterPlayerTizenExampleApp extends StatelessWidget {
  /// Creates the example application.
  const BetterPlayerTizenExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TizenVideoPlayerScreen());
  }
}

/// Screen hosting the video player instance on Tizen.
class TizenVideoPlayerScreen extends StatefulWidget {
  /// Creates the video player screen.
  const TizenVideoPlayerScreen({super.key});

  @override
  State<TizenVideoPlayerScreen> createState() => TizenVideoPlayerScreenState();
}

/// State for [TizenVideoPlayerScreen] exposing [controller] for E2E tests.
class TizenVideoPlayerScreenState extends State<TizenVideoPlayerScreen> {
  /// Active player controller instance.
  late final BetterPlayerController controller;

  @override
  void initState() {
    super.initState();
    const config = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: true,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    );
    controller = BetterPlayerController(
      config,
      betterPlayerDataSource: dataSource,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Better Player Tizen')),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlayer(controller: controller),
        ),
      ),
    );
  }
}
