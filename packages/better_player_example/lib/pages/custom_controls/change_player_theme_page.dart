import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/custom_controls/custom_controls_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change player theme')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Player with the possibility to change the theme. Click on '
                'buttons below to change theme of player.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            BetterPlayer(controller: _betterPlayerController),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MaterialButton(
                  child: const Text('MATERIAL'),
                  onPressed: () {
                    setState(() {
                      _playerTheme = PlayerTheme.material;
                      _betterPlayerController.pause();
                      _betterPlayerController = BetterPlayerController(
                        PlayerConfiguration(
                          controlsConfiguration: PlayerControlsConfiguration(
                            playerTheme: _playerTheme,
                          ),
                        ),
                        betterPlayerDataSource: _dataSource,
                      );
                    });
                  },
                ),
                MaterialButton(
                  child: const Text('CUPERTINO'),
                  onPressed: () {
                    setState(() {
                      _playerTheme = PlayerTheme.cupertino;
                      _betterPlayerController.pause();
                      _betterPlayerController = BetterPlayerController(
                        PlayerConfiguration(
                          controlsConfiguration: PlayerControlsConfiguration(
                            playerTheme: _playerTheme,
                          ),
                        ),
                        betterPlayerDataSource: _dataSource,
                      );
                    });
                  },
                ),
                MaterialButton(
                  child: const Text('CUSTOM'),
                  onPressed: () {
                    setState(() {
                      _playerTheme = PlayerTheme.custom;
                      _betterPlayerController.pause();
                      _betterPlayerController = BetterPlayerController(
                        PlayerConfiguration(
                          controlsConfiguration: PlayerControlsConfiguration(
                            playerTheme: _playerTheme,
                            customControlsBuilder:
                                (controller, onControlsVisibilityChanged) =>
                                    CustomControlsWidget(
                                      controller: controller,
                                      onControlsVisibilityChanged:
                                          onControlsVisibilityChanged,
                                    ),
                          ),
                        ),
                        betterPlayerDataSource: _dataSource,
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
