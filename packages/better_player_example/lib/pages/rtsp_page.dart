import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

class RtspPage extends StatefulWidget {
  const RtspPage({super.key});

  @override
  _RtspPageState createState() => _RtspPageState();
}

class _RtspPageState extends State<RtspPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      'rtsp://9627b0bf2a7b.entrypoint.cloud.wowza.com:1935/app-p5260J38/66abe4b9_stream1',
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
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
              'RTSP player created with a public Wowza test stream. Please note that RTSP is currently only supported on Android.',
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
