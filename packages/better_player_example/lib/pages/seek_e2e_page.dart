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
  bool _isInitialized = false;
  bool _seek10sVerified = false;

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
      if (!mounted) {
        return;
      }
      if (event.betterPlayerEventType == PlayerEventType.initialized) {
        setState(() {
          _isInitialized = true;
        });
      }
      if (event.betterPlayerEventType == PlayerEventType.progress ||
          event.betterPlayerEventType == PlayerEventType.play ||
          event.betterPlayerEventType == PlayerEventType.pause ||
          event.betterPlayerEventType == PlayerEventType.seekTo) {
        final pos =
            event.parameters?['progress'] as Duration? ??
            _betterPlayerController.videoPlayerValue?.position ??
            Duration.zero;
        setState(() {
          _isInitialized =
              _isInitialized ||
              (_betterPlayerController.videoPlayerValue?.initialized ?? false);
          _isPlaying =
              _betterPlayerController.videoPlayerValue?.isPlaying ?? false;
          _currentPosition = pos;
          if (pos.inSeconds >= 8) {
            _seek10sVerified = true;
          }
        });
      }
    });
  }

  Future<void> _seekTo10s() async {
    await _betterPlayerController.seekTo(const Duration(seconds: 10));
    final pos =
        await _betterPlayerController.position ??
        _betterPlayerController.videoPlayerValue?.position;
    if (mounted) {
      setState(() {
        if (pos != null) {
          _currentPosition = pos;
        }
        if ((pos?.inSeconds ?? 0) >= 8 || _currentPosition.inSeconds >= 8) {
          _seek10sVerified = true;
        }
      });
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
      appBar: AppBar(title: const Text('Seek E2E Test')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController),
            ),
            const SizedBox(height: 16),
            if (_isInitialized)
              Semantics(
                identifier: 'better_player_e2e_seek_initialized',
                label: 'better_player_e2e_seek_initialized',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Seek Player Initialized'),
                ),
              ),
            if (_seek10sVerified)
              Semantics(
                identifier: 'better_player_e2e_seek_10s_verified',
                label: 'better_player_e2e_seek_10s_verified',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Seek 10s Verified'),
                ),
              ),
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
                Semantics(
                  identifier: 'better_player_e2e_seek_3s_button',
                  label: 'better_player_e2e_seek_3s_button',
                  child: ElevatedButton(
                    key: const ValueKey('seek_3s'),
                    onPressed: () => _betterPlayerController.seekTo(
                      const Duration(seconds: 3),
                    ),
                    child: const Text('Seek 00:03'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_seek_10s_button',
                  label: 'better_player_e2e_seek_10s_button',
                  child: ElevatedButton(
                    key: const ValueKey('seek_10s'),
                    onPressed: _seekTo10s,
                    child: const Text('Seek 00:10'),
                  ),
                ),
                Semantics(
                  identifier: 'better_player_e2e_seek_30s_button',
                  label: 'better_player_e2e_seek_30s_button',
                  child: ElevatedButton(
                    key: const ValueKey('seek_30s'),
                    onPressed: () => _betterPlayerController.seekTo(
                      const Duration(seconds: 30),
                    ),
                    child: const Text('Seek 00:30'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
