import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/material.dart';

class DisabledControlsPlayer extends StatefulWidget {
  const DisabledControlsPlayer({Key? key}) : super(key: key);

  @override
  _DisabledControlsPlayerState createState() => _DisabledControlsPlayerState();
}

class _DisabledControlsPlayerState extends State<DisabledControlsPlayer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Basic player"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Next player shows video from file.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: Utils.getFileUrl(Constants.fileTestVideoUrl),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.data != null) {
                return BetterPlayer(
                  controller: BetterPlayerController(
                    const BetterPlayerConfiguration(),
                    betterPlayerDataSource: BetterPlayerDataSource(BetterPlayerDataSourceType.file, snapshot.data!),
                    controlEnabled: false,
                  ),
                );
              } else {
                return const SizedBox();
              }
            },
          )
        ],
      ),
    );
  }
}
