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
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    debugPrint('FFI TEST PAGE: initState');
    super.initState();
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    _betterPlayerController.addEventsListener((event) {
      debugPrint(
        'FFI TEST PAGE: Event received: ${event.betterPlayerEventType}',
      );
      if (event.betterPlayerEventType == PlayerEventType.initialized) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      } else if (event.betterPlayerEventType == PlayerEventType.exception) {
        final error =
            event.parameters?['exception']?.toString() ?? 'Unknown error';
        debugPrint('FFI TEST PAGE: EXCEPTION: $error');
        setState(() {
          _errorMessage = error;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('FFI TEST PAGE: addPostFrameCallback');
      // Check if already initialized (e.g. if events were missed)
      if (_betterPlayerController.videoPlayerValue?.initialized ?? false) {
        debugPrint('FFI TEST PAGE: Already initialized');
        setState(() {
          _isInitialized = true;
        });
      }

      final betterPlayerDataSource = PlayerDataSource(
        DataSourceType.network,
        Constants.hlsTestStreamUrl,
      );
      debugPrint(
        'FFI TEST PAGE: Setting up data source: ${betterPlayerDataSource.url}',
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
      debugPrint('FFI Test Error ($name): $e');
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
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Semantics(
                  identifier: 'ffi_test_error_status',
                  child: Text(
                    'error=$_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (!_isInitialized)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Semantics(
                  identifier: 'ffi_test_waiting_status',
                  child: const Text(
                    'Waiting for initialization...',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Semantics(
                  identifier: 'ffi_test_initialized_status',
                  child: const Text(
                    'initialized=true',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildTestButton(
              'play',
              () async => _betterPlayerController.play(),
            ),
            _buildTestButton(
              'pause',
              () async => _betterPlayerController.pause(),
            ),
            _buildTestButton(
              'seekTo',
              () async {
                // Try to seek even if not initialized to test FFI bridge
                try {
                  await _betterPlayerController.seekTo(
                    const Duration(seconds: 5),
                  );
                } catch (e) {
                  // Fallback to direct platform call if controller logic fails
                  final textureId = _betterPlayerController.textureId;
                  if (textureId != null) {
                    await BetterPlayerPlatform.instance.seekTo(
                      textureId,
                      const Duration(seconds: 5),
                    );
                  } else {
                    rethrow;
                  }
                }
              },
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
              () async {
                await _betterPlayerController.setTrackParameters(
                  width: 1280,
                  height: 720,
                  bitrate: 2000,
                );
              },
            ),
            _buildTestButton(
              'setAudioTrack',
              () async {
                _betterPlayerController.setAudioTrack(
                  PlayerAsmsAudioTrack(label: 'English', id: 0),
                );
              },
            ),
            _buildTestButton(
              'setMixWithOthers',
              () async {
                _betterPlayerController.setMixWithOthers(true);
              },
            ),
            _buildTestButton(
              'setLooping',
              () async => _betterPlayerController.setLooping(true),
            ),
            _buildTestButton(
              'getPosition',
              () async {
                final pos = await _betterPlayerController.position;
                if (pos == null) {
                  throw Exception('getPosition returned null');
                }
                debugPrint('FFI Test getPosition result: $pos');
              },
            ),
            _buildTestButton(
              'getAbsolutePosition',
              () async {
                final absPos = await _betterPlayerController.absolutePosition;
                debugPrint('FFI Test getAbsolutePosition result: $absPos');
              },
            ),
            _buildTestButton(
              'playerValue',
              () async {
                final value = _betterPlayerController.videoPlayerValue;
                if (value == null) {
                  throw Exception('videoPlayerValue returned null');
                }
                debugPrint('FFI Test playerValue result: $value');
              },
            ),
            _buildTestButton(
              'duration',
              () async {
                final dur = _betterPlayerController.duration;
                if (dur == null || dur <= Duration.zero) {
                  throw Exception('duration returned invalid value: $dur');
                }
                debugPrint('FFI Test duration result: $dur');
              },
            ),
            _buildTestButton(
              'isInitialized',
              () async {
                final initialized = _betterPlayerController.isInitialized;
                if (!initialized) {
                  throw Exception('isInitialized returned false');
                }
                debugPrint('FFI Test isInitialized result: $initialized');
              },
            ),
            _buildTestButton(
              'isPictureInPictureSupported',
              () async {
                final supported = await _betterPlayerController
                    .isPictureInPictureSupported();
                debugPrint(
                  'FFI Test isPictureInPictureSupported result: $supported',
                );
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
            const SizedBox(height: 400),
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
