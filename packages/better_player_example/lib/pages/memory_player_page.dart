import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:better_player_example/utils/example_io_utils.dart';
import 'package:material_ui/material_ui.dart';

class MemoryPlayerPage extends StatefulWidget {
  const MemoryPlayerPage({super.key});

  @override
  _MemoryPlayerPageState createState() => _MemoryPlayerPageState();
}

class _MemoryPlayerPageState extends State<MemoryPlayerPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _setupDataSource();
    super.initState();
  }

  Future<void> _setupDataSource() async {
    try {
      final filePath = await Utils.getFileUrl(Constants.fileTestVideoUrl);
      final bytes = await ExampleIoUtils.readBytesFromFile(filePath);
      final dataSource = PlayerDataSource(
        DataSourceType.memory,
        '',
        videoExtension: 'mp4',
        bytes: bytes,
      );
      _betterPlayerController.setupDataSource(dataSource);
    } catch (e) {
      debugPrint('Failed to load memory data source: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory player')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Memory player with plays video from bytes list. In this example'
              'file bytes are read to list and then used in player.',
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
