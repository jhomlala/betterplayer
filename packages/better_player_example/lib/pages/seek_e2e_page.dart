import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class SeekE2EPage extends StatefulWidget {
  const SeekE2EPage({super.key});

  @override
  State<SeekE2EPage> createState() => _SeekE2EPageState();
}

class _SeekE2EPageState extends State<SeekE2EPage> {
  late BetterPlayerController _betterPlayerController;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    const betterPlayerConfiguration = PlayerConfiguration(
      autoPlay: true,
      looping: true,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final betterPlayerDataSource = PlayerDataSource(
        DataSourceType.network,
        Constants.bugBuckBunnyVideoUrl,
      );
      _betterPlayerController.setupDataSource(betterPlayerDataSource);
    });

    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == PlayerEventType.progress ||
          event.betterPlayerEventType == PlayerEventType.play ||
          event.betterPlayerEventType == PlayerEventType.pause) {
        setState(() {
          _isPlaying =
              _betterPlayerController.videoPlayerValue?.isPlaying ?? false;
          _currentPosition =
              event.parameters?['progress'] as Duration? ??
              _betterPlayerController.videoPlayerValue?.position ??
              Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seek E2E Test')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          const SizedBox(height: 16),
          Text(
            'Position: ${_currentPosition.inSeconds}s',
            key: const ValueKey('position_text'),
            semanticsLabel: 'better_player_e2e_position',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'State: ${_isPlaying ? "Playing" : "Paused"}',
            key: const ValueKey('state_text'),
            semanticsLabel: 'better_player_e2e_state',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                key: const ValueKey('seek_3s'),
                onPressed: () =>
                    _betterPlayerController.seekTo(const Duration(seconds: 3)),
                child: const Text('Seek 00:03'),
              ),
              ElevatedButton(
                key: const ValueKey('seek_10s'),
                onPressed: () =>
                    _betterPlayerController.seekTo(const Duration(seconds: 10)),
                child: const Text('Seek 00:10'),
              ),
              ElevatedButton(
                key: const ValueKey('seek_30s'),
                onPressed: () =>
                    _betterPlayerController.seekTo(const Duration(seconds: 30)),
                child: const Text('Seek 00:30'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
