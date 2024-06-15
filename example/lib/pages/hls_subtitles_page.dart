import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:flutter/material.dart';

class HlsSubtitlesPage extends StatefulWidget {
  const HlsSubtitlesPage({super.key});

  @override
  _HlsSubtitlesPageState createState() => _HlsSubtitlesPageState();
}

class _HlsSubtitlesPageState extends State<HlsSubtitlesPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const controlsConfiguration = BetterPlayerControlsConfiguration(
      controlBarColor: Colors.black26,
      progressBarPlayedColor: Colors.indigo,
      progressBarHandleColor: Colors.indigo,
      controlBarHeight: 40,
      loadingColor: Colors.red,
      overflowModalColor: Colors.black54,
      overflowModalTextColor: Colors.white,
      overflowMenuIconsColor: Colors.white,
    );

    final betterPlayerConfiguration = const BetterPlayerConfiguration(
      controlsConfiguration: controlsConfiguration,
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
        fontSize: 16,
      ),
    );
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.hlsPlaylistUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HLS subtitles'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Player with HLS stream which loads subtitles from HLS.'
                ' You can choose subtitles by using overflow menu (3 dots in right corner).',
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
