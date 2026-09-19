import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

class RtspPage extends StatefulWidget {
  const RtspPage({super.key});

  @override
  _RtspPageState createState() => _RtspPageState();
}

class _RtspPageState extends State<RtspPage> {
  late BetterPlayerController _betterPlayerController;
  final TextEditingController _urlController = TextEditingController(
    text: 'rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4',
  );

  @override
  void initState() {
    super.initState();
    _setupPlayer(_urlController.text);
  }

  void _setupPlayer(String url) {
    if (url.isEmpty) return;

    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      url,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RTSP player')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'RTSP player. Note that RTSP is currently only supported on Android. Public RTSP streams often go offline or block connections, so if you get a 403 or loading error, it means the server blocked it.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'RTSP URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _betterPlayerController.dispose();
                      _setupPlayer(_urlController.text);
                    });
                  },
                  child: const Text('Load'),
                ),
              ],
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
