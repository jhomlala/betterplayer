import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class ControlsAlwaysVisiblePage extends StatefulWidget {
  @override
  _ControlsAlwaysVisiblePageState createState() =>
      _ControlsAlwaysVisiblePageState();
}

class _ControlsAlwaysVisiblePageState extends State<ControlsAlwaysVisiblePage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      handleLifecycle: true,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _setupDataSource();
    super.initState();
  }

  void _setupDataSource() async {
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Controls always visible"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Controls are always visible. Click on button below to"
              " enable/disable this mode.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          ElevatedButton(
              onPressed: () {
                _betterPlayerController.setControlsAlwaysVisible(
                    !(_betterPlayerController.controlsAlwaysVisible));
              },
              child: Text("Toggle always visible controls"))
        ],
      ),
    );
  }
}
