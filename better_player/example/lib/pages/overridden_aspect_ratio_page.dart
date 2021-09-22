import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class OverriddenAspectRatioPage extends StatefulWidget {
  @override
  _OverriddenAspectRatioPageState createState() =>
      _OverriddenAspectRatioPageState();
}

class _OverriddenAspectRatioPageState extends State<OverriddenAspectRatioPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.fill,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, Constants.forBiggerBlazesUrl);
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.setOverriddenAspectRatio(1.0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Overridden aspect ratio"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Player with different rotation and fit.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 1.0,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }
}
