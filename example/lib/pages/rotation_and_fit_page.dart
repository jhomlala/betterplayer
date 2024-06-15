import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:flutter/material.dart';

class RotationAndFitPage extends StatefulWidget {
  const RotationAndFitPage({super.key});

  @override
  _RotationAndFitPageState createState() => _RotationAndFitPageState();
}

class _RotationAndFitPageState extends State<RotationAndFitPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 1,
      rotation: 90,
    );
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.forBiggerBlazesUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotation and fit'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Player with different rotation and fit.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }
}
