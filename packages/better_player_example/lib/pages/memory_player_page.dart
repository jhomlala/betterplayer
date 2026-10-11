import 'package:better_player/better_player.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:flutter/services.dart';
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
      final byteData = await rootBundle.load('assets/testvideo.mp4');
      final bytes = byteData.buffer.asUint8List();
      final dataSource = PlayerDataSource(
        DataSourceType.memory,
        '',
        videoExtension: 'mp4',
        bytes: bytes,
      );
      await _betterPlayerController.setupDataSource(dataSource);
    } catch (e) {
      debugPrint('Failed to load memory data source: $e');
    }
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Video Source')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'In-Memory Byte Array Playback',
                description:
                    'Streams directly from raw Uint8List byte arrays loaded in RAM '
                    'without persisting files to disk.',
                instructions:
                    'Useful for encrypted memory blocks or dynamically decoded buffers.',
                icon: Icons.memory_outlined,
              ),
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
