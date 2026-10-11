import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/custom_controls/custom_controls_widget.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class ChangePlayerThemePage extends StatefulWidget {
  const ChangePlayerThemePage({super.key});

  @override
  _ChangePlayerThemePageState createState() => _ChangePlayerThemePageState();
}

class _ChangePlayerThemePageState extends State<ChangePlayerThemePage> {
  late BetterPlayerController _betterPlayerController;
  PlayerDataSource? _dataSource;
  PlayerTheme _playerTheme = PlayerTheme.material;

  @override
  void initState() {
    super.initState();
    const url = Constants.bugBuckBunnyVideoUrl;
    _dataSource = PlayerDataSource(DataSourceType.network, url);
    _betterPlayerController = BetterPlayerController(
      PlayerConfiguration(
        controlsConfiguration: PlayerControlsConfiguration(
          playerTheme: _playerTheme,
        ),
      ),
      betterPlayerDataSource: _dataSource,
    );
  }

  void _updateTheme(PlayerTheme newTheme) {
    setState(() {
      _playerTheme = newTheme;
      _betterPlayerController.pause();
      _betterPlayerController = BetterPlayerController(
        PlayerConfiguration(
          controlsConfiguration: PlayerControlsConfiguration(
            playerTheme: _playerTheme,
            customControlsBuilder: newTheme == PlayerTheme.custom
                ? (controller, onControlsVisibilityChanged) =>
                      CustomControlsWidget(
                        controller: controller,
                        onControlsVisibilityChanged:
                            onControlsVisibilityChanged,
                      )
                : null,
          ),
        ),
        betterPlayerDataSource: _dataSource,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Themes & Custom Controls')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            children: [
              const DemoHeader(
                title: 'Control Bar Themes',
                description:
                    'Switch instantly between Material, Cupertino, or completely custom '
                    'built-in UI widgets via PlayerControlsConfiguration.',
                instructions:
                    'Select a theme below to rebuild player control overlays.',
                icon: Icons.palette_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<PlayerTheme>(
                  segments: const [
                    ButtonSegment(
                      value: PlayerTheme.material,
                      label: Text('Material'),
                      icon: Icon(Icons.android),
                    ),
                    ButtonSegment(
                      value: PlayerTheme.cupertino,
                      label: Text('Cupertino'),
                      icon: Icon(Icons.apple),
                    ),
                    ButtonSegment(
                      value: PlayerTheme.custom,
                      label: Text('Custom UI'),
                      icon: Icon(Icons.brush),
                    ),
                  ],
                  selected: {_playerTheme},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      _updateTheme(selected.first);
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
