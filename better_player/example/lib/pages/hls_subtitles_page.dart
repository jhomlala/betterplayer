import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class HlsSubtitlesPage extends StatefulWidget {
  @override
  _HlsSubtitlesPageState createState() => _HlsSubtitlesPageState();
}

class _HlsSubtitlesPageState extends State<HlsSubtitlesPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerControlsConfiguration controlsConfiguration =
        BetterPlayerControlsConfiguration(
      controlBarColor: Colors.black26,
      iconsColor: Colors.white,
      playIcon: Icons.play_arrow_outlined,
      progressBarPlayedColor: Colors.indigo,
      progressBarHandleColor: Colors.indigo,
      skipBackIcon: Icons.replay_10_outlined,
      skipForwardIcon: Icons.forward_10_outlined,
      backwardSkipTimeInMilliseconds: 10000,
      forwardSkipTimeInMilliseconds: 10000,
      enableSkips: true,
      enableFullscreen: true,
      enablePip: true,
      enablePlayPause: true,
      enableMute: true,
      enableAudioTracks: true,
      enableProgressText: true,
      enableSubtitles: true,
      showControlsOnInitialize: true,
      enablePlaybackSpeed: true,
      controlBarHeight: 40,
      loadingColor: Colors.red,
      overflowModalColor: Colors.black54,
      overflowModalTextColor: Colors.white,
      overflowMenuIconsColor: Colors.white,
    );

    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
            controlsConfiguration: controlsConfiguration,
            aspectRatio: 16 / 9,
            fit: BoxFit.contain,
            subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
              fontSize: 16.0,
            ));
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, Constants.hlsPlaylistUrl,
        useAsmsSubtitles: true);
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HLS subtitles"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Player with HLS stream which loads subtitles from HLS."
                " You can choose subtitles by using overflow menu (3 dots in right corner).",
                style: TextStyle(fontSize: 16),
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController),
            ),
          ],
        ),
      ),
    );
  }
}
