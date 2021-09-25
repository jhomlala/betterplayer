import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class NormalPlayerPage extends StatefulWidget {
  @override
  _NormalPlayerPageState createState() => _NormalPlayerPageState();
}

class _NormalPlayerPageState extends State<NormalPlayerPage> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerDataSource _betterPlayerDataSource;


  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlayerListVideoPlayer(
            BetterPlayerDataSource(
                BetterPlayerDataSourceType.network,
               Constants.forBiggerBlazesUrl,
            ),
            playFraction: 0.8,
            configuration: BetterPlayerConfiguration(autoDispose: false),
          ),
        ),
      ],
    );
  }
}
