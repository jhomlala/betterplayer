import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class FFITestPage extends StatefulWidget {
  const FFITestPage({super.key});

  @override
  _FFITestPageState createState() => _FFITestPageState();
}

class _FFITestPageState extends State<FFITestPage> {
  late BetterPlayerController _betterPlayerController;
  final Map<String, bool?> _results = {};

  @override
  void initState() {
    super.initState();
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _betterPlayerController =
        BetterPlayerController(betterPlayerConfiguration);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final betterPlayerDataSource = PlayerDataSource(
        DataSourceType.network,
        Constants.bugBuckBunnyVideoUrl,
      );
      _betterPlayerController.setupDataSource(betterPlayerDataSource);
    });
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  Future<void> _runTest(String name, Future<void> Function() action) async {
    try {
      await action();
      setState(() {
        _results[name] = true;
      });
    } catch (e) {
      BetterPlayerUtils.log('FFI Test Error ($name): $e');
      setState(() {
        _results[name] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FFI Method Test')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController),
            ),
            const SizedBox(height: 16),
            _buildTestButton('play', () async => _betterPlayerController.play()),
            _buildTestButton(
              'pause',
              () async => _betterPlayerController.pause(),
            ),
            _buildTestButton(
              'seekTo',
              () async =>
                  _betterPlayerController.seekTo(const Duration(seconds: 5)),
            ),
            _buildTestButton(
              'setVolume',
              () async => _betterPlayerController.setVolume(0.8),
            ),
            _buildTestButton(
              'setSpeed',
              () async => _betterPlayerController.setSpeed(1.2),
            ),
            _buildTestButton(
              'setTrackParameters',
              () async => _betterPlayerController.videoPlayerController
                  ?.setTrackParameters(1280, 720, 2000),
            ),
            _buildTestButton(
              'setAudioTrack',
              () async => _betterPlayerController.videoPlayerController
                  ?.setAudioTrack('English', 0),
            ),
            _buildTestButton(
              'setMixWithOthers',
              () async => _betterPlayerController.setMixWithOthers(true),
            ),
            _buildTestButton(
              'setLooping',
              () async => _betterPlayerController.setLooping(true),
            ),
            _buildTestButton(
              'getPosition',
              () async {
                final pos = await _betterPlayerController.videoPlayerController?.position;
                if (pos == null) throw Exception('Position is null');
              },
            ),
            _buildTestButton(
              'getAbsolutePosition',
              () async {
                await _betterPlayerController.videoPlayerController?.absolutePosition;
              },
            ),
            _buildTestButton(
              'isPictureInPictureSupported',
              () async {
                await _betterPlayerController.isPictureInPictureSupported();
              },
            ),
            _buildTestButton(
              'enablePictureInPicture',
              () async {
                await _betterPlayerController.enablePictureInPicture();
              },
            ),
            _buildTestButton(
              'disablePictureInPicture',
              () async {
                await _betterPlayerController.disablePictureInPicture();
              },
            ),
            _buildTestButton(
              'preCache',
              () async => _betterPlayerController.preCache(
                PlayerDataSource(
                  DataSourceType.network,
                  Constants.bugBuckBunnyVideoUrl,
                ),
              ),
            ),
            _buildTestButton(
              'stopPreCache',
              () async => _betterPlayerController.stopPreCache(
                PlayerDataSource(
                  DataSourceType.network,
                  Constants.bugBuckBunnyVideoUrl,
                ),
              ),
            ),
            _buildTestButton(
              'clearCache',
              () async => _betterPlayerController.clearCache(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String name, Future<void> Function() action) {
    final result = _results[name];
    var status = 'not started';
    var color = Colors.grey;
    if (result == true) {
      status = 'success=true';
      color = Colors.green;
    } else if (result == false) {
      status = 'success=false';
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              identifier: 'ffi_test_button_$name',
              child: ElevatedButton(
                onPressed: () => _runTest(name, action),
                child: Text('Test $name'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            identifier: 'ffi_test_status_$name',
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
