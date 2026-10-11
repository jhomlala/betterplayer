import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class ControlsConfigurationPage extends StatefulWidget {
  const ControlsConfigurationPage({super.key});

  @override
  _ControlsConfigurationPageState createState() =>
      _ControlsConfigurationPageState();
}

class _ControlsConfigurationPageState extends State<ControlsConfigurationPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    final controlsConfiguration = PlayerControlsConfiguration(
      controlBarColor: Colors.indigoAccent.withAlpha(200),
      iconsColor: Colors.lightGreen,
      playIcon: Icons.forward,
      progressBarPlayedColor: Colors.grey,
      progressBarHandleColor: Colors.lightGreen,
      enableSkips: false,
      enableFullscreen: false,
      controlBarHeight: 60,
      loadingColor: Colors.red,
      overflowModalColor: Colors.indigo,
      overflowModalTextColor: Colors.white,
      overflowMenuIconsColor: Colors.white,
    );

    final betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      controlsConfiguration: controlsConfiguration,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controls Configuration')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Customized Built-in Controls',
                description:
                    'Tailors colors, control bar dimensions, icons, and action '
                    'visibilities via PlayerControlsConfiguration.',
                instructions:
                    'Observe custom green play icon, tinted scrubber, and disabled skips.',
                icon: Icons.palette_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _betterPlayerController.setPlayerControlsConfiguration(
                        const PlayerControlsConfiguration(
                          overflowModalColor: Colors.amberAccent,
                        ),
                      );
                    });
                  },
                  label: const Text('Switch Controls Theme Dynamically'),
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
