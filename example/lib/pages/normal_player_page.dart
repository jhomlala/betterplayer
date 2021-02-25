import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/rotation_and_fit_page.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/material.dart';

class NormalPlayerPage extends StatefulWidget {
  @override
  _NormalPlayerPageState createState() => _NormalPlayerPageState();
}

class _NormalPlayerPageState extends State<NormalPlayerPage> {
  BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
          autoPlay: true,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.elephantDreamStreamUrl,
      videoFormat: BetterPlayerVideoFormat.hls,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(milliseconds: 300), (){
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RotationAndFitPage()),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("DRM page"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "AES DRM example.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          ElevatedButton(
            child: Text("Play file data source"),
            onPressed: () async {
              return Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RotationAndFitPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
