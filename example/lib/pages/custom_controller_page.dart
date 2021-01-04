import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/custom_controls/CustomControlsWidget.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/material.dart';

class CustomControllerPage extends StatefulWidget {
  @override
  _CustomControllerPageState createState() => _CustomControllerPageState();
}

class _CustomControllerPageState extends State<CustomControllerPage> {
  BetterPlayerController _betterPlayerControllerMaterial;
  BetterPlayerController _betterPlayerControllerCupertino;
  BetterPlayerController _betterPlayerControllerCustom;

  @override
  void initState() {
    super.initState();
    _initPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Custom Controller Page"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Player with forced Material configuration",
                style: TextStyle(fontSize: 16),
              ),
            ),
            BetterPlayer(
              controller: _betterPlayerControllerMaterial,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Player with forced Cupertino configuration",
                style: TextStyle(fontSize: 16),
              ),
            ),
            BetterPlayer(
              controller: _betterPlayerControllerCupertino,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Player with custom Controls configuration",
                style: TextStyle(fontSize: 16),
              ),
            ),
            BetterPlayer(
              controller: _betterPlayerControllerCustom,
            ),
          ],
        ),
      ),
    );
  }

  void _initPlayers() {
    String url =
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    BetterPlayerDataSource dataSource =
        BetterPlayerDataSource(BetterPlayerDataSourceType.network, url);

    _betterPlayerControllerMaterial = new BetterPlayerController(
      BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
        playerPlatform: PlayerPlatform.ANDROID,
      )),
      betterPlayerDataSource: dataSource,
    );
    _betterPlayerControllerCupertino = new BetterPlayerController(
      BetterPlayerConfiguration(
          controlsConfiguration: BetterPlayerControlsConfiguration(
        playerPlatform: PlayerPlatform.IOS,
      )),
      betterPlayerDataSource: dataSource,
    );
    _betterPlayerControllerCustom = new BetterPlayerController(
      BetterPlayerConfiguration(
        controlsConfiguration: BetterPlayerControlsConfiguration(
          customControls: (controller) => CustomControlsWidget(
            controller: controller,
          ),
        ),
      ),
      betterPlayerDataSource: dataSource,
    );
  }
}
