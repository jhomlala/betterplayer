import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:material_ui/material_ui.dart';

class SubtitlesPage extends StatefulWidget {
  const SubtitlesPage({super.key});

  @override
  _SubtitlesPageState createState() => _SubtitlesPageState();
}

class _SubtitlesPageState extends State<SubtitlesPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      subtitlesConfiguration: PlayerSubtitlesConfiguration(
        backgroundColor: Colors.green,
        fontSize: 20,
      ),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == PlayerEventType.progress) {
        BetterPlayerLogger.instance.info(
          'Current subtitle line: ${_betterPlayerController.renderedSubtitle}',
        );
      }
    });
    _setupDataSource();
    super.initState();
  }

  Future<void> _setupDataSource() async {
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
      subtitles: PlayerSubtitlesSource.single(
        type: PlayerSubtitlesSourceType.file,
        url: await Utils.getFileUrl(Constants.fileExampleSubtitlesUrl),
        name: 'My subtitles',
        selectedByDefault: true,
      ),
    );
    _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subtitles')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Player with subtitles loaded from file. Subtitles are enabled by default.'
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
    );
  }
}
