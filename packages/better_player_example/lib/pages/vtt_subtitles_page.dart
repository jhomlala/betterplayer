import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class VttSubtitlesPage extends StatefulWidget {
  const VttSubtitlesPage({super.key});

  @override
  _VttSubtitlesPageState createState() => _VttSubtitlesPageState();
}

class _VttSubtitlesPageState extends State<VttSubtitlesPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      subtitlesConfiguration: PlayerSubtitlesConfiguration(
        backgroundColor: Colors.black87,
        fontSize: 22,
      ),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == PlayerEventType.progress) {
        debugPrint(
          'Current VTT subtitle line: ${_betterPlayerController.renderedSubtitle}',
        );
      }
    });
    _setupDataSource();
    super.initState();
  }

  Future<void> _setupDataSource() async {
    List<PlayerSubtitlesSource>? subtitlesSource;
    if (kIsWeb) {
      final content = await rootBundle.loadString(
        'assets/example_subtitles.vtt',
      );
      subtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.memory,
        content: content,
        name: 'WebVTT subtitles',
        selectedByDefault: true,
      );
    } else {
      subtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.file,
        url: await Utils.getFileUrl('example_subtitles.vtt'),
        name: 'WebVTT subtitles',
        selectedByDefault: true,
      );
    }

    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
      subtitles: subtitlesSource,
    );
    _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebVTT Subtitles')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Player with WebVTT subtitles supporting inline formatting tags (<b>, <i>, <u>, <c.color>) '
              'and cue alignment (align:start, center, end).',
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }
}
