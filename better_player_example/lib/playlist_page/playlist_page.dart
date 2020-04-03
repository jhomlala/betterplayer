import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<BetterPlayerDataSource> playlistDataSource = List();

  @override
  void initState() {
    playlistDataSource.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"));
    playlistDataSource.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
              "Playlist widget will load automatically next video once current "
              "finishes. User can't use player controls when video is changing."),
        ),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlaylist(
            betterPlayerDataSourceList: playlistDataSource,
            betterPlayerSettings: BetterPlayerSettings(),
            betterPlayerPlaylistSettings: BetterPlayerPlaylistSettings(),
          ),
        )
      ]),
    );
  }
}
