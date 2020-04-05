import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List dataSourceList = List<BetterPlayerDataSource>();

  Future<List<BetterPlayerDataSource>> setupData() async {
    await _saveAssetToFile();

    final directory = await getApplicationDocumentsDirectory();

    dataSourceList.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        subtitles: BetterPlayerSubtitlesSource(
            type: BetterPlayerSubtitlesSourceType.FILE,
            url: "${directory.path}/example_subtitles.srt")));

    dataSourceList.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"));
    dataSourceList.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "http://sample.vodobox.com/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8",
        liveStream: true));

    return dataSourceList;
  }

  Future _saveAssetToFile() async {
    String content =
        await rootBundle.loadString("assets/example_subtitles.srt");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/example_subtitles.srt");
    file.writeAsString(content);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BetterPlayerDataSource>>(
      future: setupData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Building!");
        } else {
          return ListView(children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                  "Playlist widget will load automatically next video once current "
                  "finishes. User can't use player controls when video is changing."),
            ),
            AspectRatio(
              child: BetterPlayerPlaylist(
                betterPlayerConfiguration: BetterPlayerConfiguration(
                    autoPlay: false,
                    subtitlesConfiguration:
                        BetterPlayerSubtitlesConfiguration(fontSize: 10),
                    controlsConfiguration:
                        BetterPlayerControlsConfiguration.cupertino()),
                betterPlayerPlaylistConfiguration:
                    const BetterPlayerPlaylistConfiguration(),
                betterPlayerDataSourceList: snapshot.data,
              ),
              aspectRatio: 16 / 9,
            )
          ]);
        }
      },
    );
  }
}
