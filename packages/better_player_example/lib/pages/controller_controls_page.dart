import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class ControllerControlsPage extends StatefulWidget {
  const ControllerControlsPage({super.key});

  @override
  _ControllerControlsPageState createState() => _ControllerControlsPageState();
}

class _ControllerControlsPageState extends State<ControllerControlsPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programmatic Controls')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'External Controller API',
                description:
                    'Drive playback programmatically via BetterPlayerController '
                    'methods without relying on internal player UI controls.',
                instructions:
                    'Use the action buttons below to remotely command playback and UI state.',
                icon: Icons.tune_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _betterPlayerController.play,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _betterPlayerController.pause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _betterPlayerController.setControlsVisibility(false);
                      },
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Hide Controls'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _betterPlayerController.setControlsVisibility(true);
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Show Controls'),
                    ),
                  ],
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
