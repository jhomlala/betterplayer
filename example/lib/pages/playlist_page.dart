import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List dataSourceList = List<BetterPlayerDataSource>();

  Future<List<BetterPlayerDataSource>> setupData() async {
    dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        Constants.forBiggerBlazesUrl,
        subtitles: BetterPlayerSubtitlesSource.single(
            type: BetterPlayerSubtitlesSourceType.FILE,
            url: await Utils.getFileUrl(Constants.fileExampleSubtitlesUrl)),
      ),
    );

    dataSourceList.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK, Constants.bugBuckBunnyVideoUrl));
    dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        Constants.phantomVideoUrl,
        liveStream: true,
      ),
    );

    return dataSourceList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Playlist"),
      ),
      body: FutureBuilder<List<BetterPlayerDataSource>>(
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
                      autoPlay: true,
                      aspectRatio: 1,
                      fit: BoxFit.cover,
                      subtitlesConfiguration:
                          BetterPlayerSubtitlesConfiguration(fontSize: 10),
                      controlsConfiguration:
                          BetterPlayerControlsConfiguration.cupertino(),
                      deviceOrientationsAfterFullScreen: [
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.portraitDown,
                      ]),
                  betterPlayerPlaylistConfiguration:
                      BetterPlayerPlaylistConfiguration(
                          loopVideos: true,
                          nextVideoDelay: Duration(seconds: 5)),
                  betterPlayerDataSourceList: snapshot.data,
                ),
                aspectRatio: 1,
              )
            ]);
          }
        },
      ),
    );
  }
}
