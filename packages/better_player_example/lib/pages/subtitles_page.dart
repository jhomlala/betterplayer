import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class SubtitlesPage extends StatefulWidget {
  const SubtitlesPage({super.key});

  @override
  _SubtitlesPageState createState() => _SubtitlesPageState();
}

class _SubtitlesPageState extends State<SubtitlesPage> {
  late BetterPlayerController _betterPlayerControllerSrt;
  late BetterPlayerController _betterPlayerControllerVtt;
  late BetterPlayerController _betterPlayerControllerTtml;

  @override
  void initState() {
    const betterPlayerConfigurationSrt = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      subtitlesConfiguration: PlayerSubtitlesConfiguration(
        backgroundColor: Colors.black87,
        fontSize: 18,
      ),
    );

    const betterPlayerConfigurationVtt = PlayerConfiguration(
      subtitlesConfiguration: PlayerSubtitlesConfiguration(
        backgroundColor: Colors.black87,
        fontSize: 18,
      ),
    );

    const betterPlayerConfigurationTtml = PlayerConfiguration(
      subtitlesConfiguration: PlayerSubtitlesConfiguration(
        backgroundColor: Colors.black87,
        fontSize: 18,
      ),
    );

    _betterPlayerControllerSrt = BetterPlayerController(
      betterPlayerConfigurationSrt,
    );
    _betterPlayerControllerVtt = BetterPlayerController(
      betterPlayerConfigurationVtt,
    );
    _betterPlayerControllerTtml = BetterPlayerController(
      betterPlayerConfigurationTtml,
    );

    _setupDataSources();
    super.initState();
  }

  Future<void> _setupDataSources() async {
    // SRT Source
    List<PlayerSubtitlesSource>? srtSubtitlesSource;
    if (kIsWeb) {
      final content = await rootBundle.loadString(
        'assets/example_subtitles.srt',
      );
      srtSubtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.memory,
        content: content,
        name: 'SRT Subtitles',
        selectedByDefault: true,
      );
    } else {
      srtSubtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.file,
        url: await Utils.getFileUrl(Constants.fileExampleSubtitlesUrl),
        name: 'SRT Subtitles',
        selectedByDefault: true,
      );
    }

    final srtDataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
      subtitles: srtSubtitlesSource,
    );
    _betterPlayerControllerSrt.setupDataSource(srtDataSource);

    // WebVTT Source
    List<PlayerSubtitlesSource>? vttSubtitlesSource;
    if (kIsWeb) {
      final content = await rootBundle.loadString(
        'assets/example_subtitles.vtt',
      );
      vttSubtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.memory,
        content: content,
        name: 'WebVTT Subtitles',
        selectedByDefault: true,
      );
    } else {
      vttSubtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.file,
        url: await Utils.getFileUrl('example_subtitles.vtt'),
        name: 'WebVTT Subtitles',
        selectedByDefault: true,
      );
    }

    final vttDataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
      subtitles: vttSubtitlesSource,
    );
    _betterPlayerControllerVtt.setupDataSource(vttDataSource);

    // TTML Source
    List<PlayerSubtitlesSource>? ttmlSubtitlesSource;
    if (kIsWeb) {
      final content = await rootBundle.loadString(
        'assets/example_subtitles.ttml',
      );
      ttmlSubtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.memory,
        content: content,
        name: 'TTML Subtitles',
        selectedByDefault: true,
      );
    } else {
      ttmlSubtitlesSource = PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.file,
        url: await Utils.getFileUrl('example_subtitles.ttml'),
        name: 'TTML Subtitles',
        selectedByDefault: true,
      );
    }

    final ttmlDataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
      subtitles: ttmlSubtitlesSource,
    );
    _betterPlayerControllerTtml.setupDataSource(ttmlDataSource);
  }

  @override
  void dispose() {
    _betterPlayerControllerSrt.dispose();
    _betterPlayerControllerVtt.dispose();
    _betterPlayerControllerTtml.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subtitles & WebVTT & TTML Examples')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '1. SRT Subtitles Example',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Player with standard SRT subtitles loaded from file.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerControllerSrt),
          ),
          const Divider(height: 32, thickness: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '2. WebVTT Subtitles Advanced Example',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Player with WebVTT subtitles demonstrating inline formatting tags '
              '(<b>, <i>, <u>, <c.color>, <v> voice tags) and alignments.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerControllerVtt),
          ),
          const Divider(height: 32, thickness: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '3. TTML Subtitles Example',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Player with TTML (Timed Text Markup Language) subtitles '
              'demonstrating XML styling, colors, regions, and line breaks.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerControllerTtml),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
