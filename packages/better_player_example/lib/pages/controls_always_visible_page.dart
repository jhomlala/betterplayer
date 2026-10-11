import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class ControlsAlwaysVisiblePage extends StatefulWidget {
  const ControlsAlwaysVisiblePage({super.key});

  @override
  _ControlsAlwaysVisiblePageState createState() =>
      _ControlsAlwaysVisiblePageState();
}

class _ControlsAlwaysVisiblePageState extends State<ControlsAlwaysVisiblePage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _setupDataSource();
    super.initState();
  }

  Future<void> _setupDataSource() async {
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persistent Controls')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Always Visible Control Bar',
                description:
                    'Prevents automatic fade-out timeout on control overlays so playback '
                    'controls remain permanently pinned to screen.',
                instructions:
                    'Tap toggle button below to enable or disable persistent overlay mode.',
                icon: Icons.visibility_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.toggle_on_outlined),
                  onPressed: () {
                    setState(() {
                      _betterPlayerController.setControlsAlwaysVisible(
                        !_betterPlayerController.controlsAlwaysVisible,
                      );
                    });
                  },
                  label: const Text('Toggle Always-Visible Controls'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
