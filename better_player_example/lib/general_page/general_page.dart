import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class GeneralPage extends StatefulWidget {
  @override
  _GeneralPageState createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  BetterPlayerController _betterPlayerController;

  Future<BetterPlayerController> setupData() async {
    await _saveAssetToFile();

    final directory = await getApplicationDocumentsDirectory();

    var dataSource = BetterPlayerDataSource(BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        subtitlesFile: File("${directory.path}/example_subtitles.srt"));
    _betterPlayerController = BetterPlayerController(BetterPlayerSettings(),
        betterPlayerDataSource: dataSource);
    return _betterPlayerController;
  }

  Future _saveAssetToFile() async {
    String content =
        await rootBundle.loadString("assets/example_subtitles.srt");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/example_subtitles.srt");
    file.writeAsString(content);
    print("File created $file");
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Padding(
        padding: EdgeInsets.all(8),
        child: Text("This is example default video. This video is loaded from"
            " URL. Subtitles are loaded from file."),
      ),
      _buildDefaultVideo()
    ]);
  }

  Widget _buildDefaultVideo() {
    return FutureBuilder<BetterPlayerController>(
      future: setupData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          print("Building!");
          return Text("Building!");
        } else {
          print("Go!");
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(
              controller: snapshot.data,
            ),
          );
        }
      },
    );
  }
}
