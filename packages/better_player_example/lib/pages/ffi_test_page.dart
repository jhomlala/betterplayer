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
        Constants.bugBuckBunnyVideoUrl,
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

  Future<void> _runTest({
    required String name,
    required Future<void> Function() action,
  }) async {
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
      appBar: AppBar(
        title: Semantics(
          identifier: 'ffi_test_page_title',
          child: const Text('FFI Method Test'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
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
                  container: true,
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
                  container: true,
                  child: const Text(
                    'initialized=true',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                _buildTestButton(
                  name: 'play',
                  action: () async => _betterPlayerController.play(),
                ),
                _buildTestButton(
                  name: 'pause',
                  action: () async => _betterPlayerController.pause(),
                ),
                _buildTestButton(
                  name: 'seekTo',
                  action: () async {
                    var attempts = 0;
                    while (attempts < 10) {
                      if (_betterPlayerController
                              .videoPlayerValue
                              ?.initialized ==
                          true) {
                        break;
                      }
                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                      attempts++;
                    }
                    await _betterPlayerController.seekTo(
                      const Duration(seconds: 5),
                    );
                  },
                ),
                _buildTestButton(
                  name: 'setVolume',
                  action: () async => _betterPlayerController.setVolume(0.8),
                ),
                _buildTestButton(
                  name: 'setSpeed',
                  action: () async => _betterPlayerController.setSpeed(1.2),
                ),
                _buildTestButton(
                  name: 'setTrackParameters',
                  action: () async {
                    await _betterPlayerController.setTrackParameters(
                      width: 1280,
                      height: 720,
                      bitrate: 2000,
                    );
                  },
                ),
                _buildTestButton(
                  name: 'setAudioTrack',
                  action: () async {
                    _betterPlayerController.setAudioTrack(
                      PlayerAsmsAudioTrack(label: 'English', id: 0),
                    );
                  },
                ),
                _buildTestButton(
                  name: 'setMixWithOthers',
                  action: () async {
                    _betterPlayerController.setMixWithOthers(true);
                  },
                ),
                _buildTestButton(
                  name: 'setAndroidMatchFrameRate',
                  action: () async {
                    _betterPlayerController.setAndroidMatchFrameRate(true);
                  },
                ),
                _buildTestButton(
                  name: 'setLooping',
                  action: () async => _betterPlayerController.setLooping(true),
                ),
                _buildTestButton(
                  name: 'getPosition',
                  action: () async {
                    final pos = await _betterPlayerController.position;
                    if (pos == null) {
                      throw Exception('getPosition returned null');
                    }
                    debugPrint('FFI Test getPosition result: $pos');
                  },
                ),
                _buildTestButton(
                  name: 'getAbsolutePosition',
                  action: () async {
                    final absPos =
                        await _betterPlayerController.absolutePosition;
                    debugPrint('FFI Test getAbsolutePosition result: $absPos');
                  },
                ),
                _buildTestButton(
                  name: 'playerValue',
                  action: () async {
                    final value = _betterPlayerController.videoPlayerValue;
                    if (value == null) {
                      throw Exception('videoPlayerValue returned null');
                    }
                    debugPrint('FFI Test playerValue result: $value');
                  },
                ),
                _buildTestButton(
                  name: 'duration',
                  action: () async {
                    final dur = _betterPlayerController.duration;
                    if (dur == null || dur <= Duration.zero) {
                      throw Exception('duration returned invalid value: $dur');
                    }
                    debugPrint('FFI Test duration result: $dur');
                  },
                ),
                _buildTestButton(
                  name: 'isInitialized',
                  action: () async {
                    final initialized = _betterPlayerController.isInitialized;
                    if (!initialized) {
                      throw Exception('isInitialized returned false');
                    }
                    debugPrint('FFI Test isInitialized result: $initialized');
                  },
                ),
                _buildTestButton(
                  name: 'isPictureInPictureSupported',
                  action: () async {
                    final supported = await _betterPlayerController
                        .isPictureInPictureSupported();
                    debugPrint(
                      'FFI Test isPictureInPictureSupported result: $supported',
                    );
                  },
                ),
                _buildTestButton(
                  name: 'preCache',
                  action: () async => _betterPlayerController.preCache(
                    PlayerDataSource(
                      DataSourceType.network,
                      Constants.bugBuckBunnyVideoUrl,
                    ),
                  ),
                ),
                _buildTestButton(
                  name: 'stopPreCache',
                  action: () async => _betterPlayerController.stopPreCache(
                    PlayerDataSource(
                      DataSourceType.network,
                      Constants.bugBuckBunnyVideoUrl,
                    ),
                  ),
                ),
                _buildTestButton(
                  name: 'clearCache',
                  action: () async => _betterPlayerController.clearCache(),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String name,
    required Future<void> Function() action,
  }) {
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

    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Semantics(
              identifier: 'ffi_test_button_$name',
              container: true,
              button: true,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('FFI TEST PAGE: Button clicked: $name');
                  _runTest(name: name, action: action);
                },
                child: Text('Test $name'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            identifier: 'ffi_test_status_$name',
            container: true,
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
