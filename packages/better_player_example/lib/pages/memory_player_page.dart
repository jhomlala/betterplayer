import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:flutter/foundation.dart';
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
    List<int> bytes;
    if (kIsWeb) {
      final ByteData data = await rootBundle.load('assets/testvideo.mp4');
      bytes = data.buffer.asUint8List();
    } else {
      final filePath = await Utils.getFileUrl(Constants.fileTestVideoUrl);
      final file = File(filePath);
      bytes = file.readAsBytesSync().buffer.asUint8List();
    }

    final dataSource = PlayerDataSource.memory(
      bytes,
      videoExtension: 'mp4',
    );
    _betterPlayerController.setupDataSource(dataSource);
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
