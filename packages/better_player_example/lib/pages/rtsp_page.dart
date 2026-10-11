import 'package:better_player/better_player.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
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

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
      appBar: AppBar(title: const Text('RTSP Live Stream')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Real-Time Streaming Protocol (RTSP)',
                description:
                    'Low-latency camera feed protocol. Currently supported natively '
                    'on Android. Public RTSP streams may occasionally refuse connections.',
                instructions:
                    'Enter an RTSP endpoint below and press Load Stream.',
                icon: Icons.videocam_outlined,
              ),
              if (!_isAndroid)
                const PlatformNoteCard(
                  title: 'RTSP Native Support on Android Only',
                  message:
                      'Web browsers and Apple AVPlayer do not support raw RTSP streams natively. '
                      'Use HLS or WebRTC for cross-platform live streaming.',
                  icon: Icons.warning_amber_rounded,
                  isWarning: true,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'RTSP Stream URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _setupPlayer(_urlController.text),
                      child: const Text('Load Stream'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
