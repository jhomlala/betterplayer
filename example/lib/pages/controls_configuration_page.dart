import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:flutter/material.dart';

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
    final controlsConfiguration = BetterPlayerControlsConfiguration(
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

    final betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      controlsConfiguration: controlsConfiguration,
    );
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controls configuration'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Player with customized controls via BetterPlayerControlsConfiguration.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _betterPlayerController.setBetterPlayerControlsConfiguration(
                  const BetterPlayerControlsConfiguration(
                    overflowModalColor: Colors.amberAccent,
                  ),
                );
              });
            },
            child: const Text('Reset settings'),
          ),
        ],
      ),
    );
  }
}
