import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:material_ui/material_ui.dart';

class DashPage extends StatefulWidget {
  const DashPage({super.key});

  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerController _betterPlayerController2;

  @override
  void initState() {
    const betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        Constants.dashStreamUrl,
        liveStream: true,
      ),
    );

    _betterPlayerController2 = BetterPlayerController(
      betterPlayerConfiguration,
    );
    _betterPlayerController2.setupDataSource(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        Constants.dashBigBuckBunnyUrl,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    _betterPlayerController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dash page')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Player 1: Default DASH stream',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _ResolutionText(controller: _betterPlayerController),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Player 2: Big Buck Bunny',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _ResolutionText(controller: _betterPlayerController2),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolutionText extends StatelessWidget {
  const _ResolutionText({required this.controller});

  final BetterPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder(
        valueListenable: controller.videoPlayerController!,
        builder: (context, value, child) {
          return Text(
            'Resolution: ${value.size?.width.toInt() ?? 0}x${value.size?.height.toInt() ?? 0}',
            style: const TextStyle(fontSize: 14),
          );
        },
      ),
    );
  }
}
