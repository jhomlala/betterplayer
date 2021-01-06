import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class ControllerControlsPage extends StatefulWidget {
  @override
  _ControllerControlsPageState createState() => _ControllerControlsPageState();
}

class _ControllerControlsPageState extends State<ControllerControlsPage> {
  BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, Constants.elephantDreamVideoUrl);
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Controller controls page"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Control player with BetterPlayerController",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          Wrap(
            children: [
              FlatButton(
                  child: Text("Play"), onPressed: _betterPlayerController.play),
              FlatButton(
                  child: Text("Pause"),
                  onPressed: _betterPlayerController.pause),
              FlatButton(
                child: Text("Hide controls"),
                onPressed: () {
                  _betterPlayerController.setControlsVisibility(false);
                },
              ),
              FlatButton(
                child: Text("Show controls"),
                onPressed: () {
                  _betterPlayerController.setControlsVisibility(true);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
