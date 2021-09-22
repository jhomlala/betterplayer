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
  final GlobalKey<BetterPlayerPlaylistState> _betterPlayerPlaylistStateKey =
      GlobalKey();
  List<BetterPlayerDataSource> _dataSourceList = [];
  late BetterPlayerConfiguration _betterPlayerConfiguration;
  late BetterPlayerPlaylistConfiguration _betterPlayerPlaylistConfiguration;

  _PlaylistPageState() {
    _betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 1,
      fit: BoxFit.cover,
      placeholderOnTop: true,
      showPlaceholderUntilPlay: true,
      subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(fontSize: 10),
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
    _betterPlayerPlaylistConfiguration = BetterPlayerPlaylistConfiguration(
      loopVideos: true,
      nextVideoDelay: Duration(seconds: 3),
    );
  }

  Future<List<BetterPlayerDataSource>> setupData() async {
    _dataSourceList.add(
      BetterPlayerDataSource(
          BetterPlayerDataSourceType.network, Constants.forBiggerBlazesUrl,
          subtitles: BetterPlayerSubtitlesSource.single(
            type: BetterPlayerSubtitlesSourceType.file,
            url: await Utils.getFileUrl(Constants.fileExampleSubtitlesUrl),
          ),
          placeholder: Image.network(
            Constants.catImageUrl,
            fit: BoxFit.cover,
          )),
    );

    _dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        Constants.bugBuckBunnyVideoUrl,
        placeholder: Image.network(
          Constants.catImageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
    _dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        Constants.forBiggerJoyridesVideoUrl,
      ),
    );

    return _dataSourceList;
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
                  key: _betterPlayerPlaylistStateKey,
                  betterPlayerConfiguration: _betterPlayerConfiguration,
                  betterPlayerPlaylistConfiguration:
                      _betterPlayerPlaylistConfiguration,
                  betterPlayerDataSourceList: snapshot.data!,
                ),
                aspectRatio: 1,
              ),
              ElevatedButton(
                onPressed: () {
                  _betterPlayerPlaylistController!.setupDataSource(0);
                },
                child: Text("Change to first data source"),
              ),
              ElevatedButton(
                onPressed: () {
                  _betterPlayerPlaylistController!.setupDataSource(2);
                },
                child: Text("Change to last source"),
              ),
              ElevatedButton(
                onPressed: () {
                  print("Currently playing video: " +
                      _betterPlayerPlaylistController!.currentDataSourceIndex
                          .toString());
                },
                child: Text("Check currently playing video index"),
              ),
              ElevatedButton(
                onPressed: () {
                  _betterPlayerPlaylistController!.betterPlayerController!
                      .pause();
                },
                child: Text("Pause current video with BetterPlayerController"),
              ),
              ElevatedButton(
                onPressed: () {
                  var list = [
                    BetterPlayerDataSource(
                      BetterPlayerDataSourceType.network,
                      Constants.bugBuckBunnyVideoUrl,
                      placeholder: Image.network(
                        Constants.catImageUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  ];
                  _betterPlayerPlaylistController?.setupDataSourceList(list);
                },
                child: Text("Setup new data source list"),
              ),
            ]);
          }
        },
      ),
    );
  }

  BetterPlayerPlaylistController? get _betterPlayerPlaylistController =>
      _betterPlayerPlaylistStateKey
          .currentState!.betterPlayerPlaylistController;
}
