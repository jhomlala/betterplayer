import 'dart:async';
import 'package:better_player/better_player.dart';
import 'package:better_player_cast/better_player_cast.dart';
import 'package:better_player_example/utils/e2e_cast_mock_server.dart';
import 'package:better_player_example/utils/e2e_cast_tcp_socket.dart';
import 'package:better_player_example/utils/e2e_fake_cast_discovery.dart';
import 'package:better_player_example/utils/e2e_local_media_server.dart';
import 'package:material_ui/material_ui.dart';

/// E2E test page for exercising Cast discovery, connection, and control flows.
class CastE2EPage extends StatefulWidget {
  /// Creates the Cast E2E page.
  const CastE2EPage({super.key});

  @override
  State<CastE2EPage> createState() => _CastE2EPageState();
}

class _CastE2EPageState extends State<CastE2EPage> {
  final E2ECastMockServer _mockServer = E2ECastMockServer();
  late BetterPlayerController _controller;
  late BetterPlayerCastExtension _castExtension;
  late E2EFakeCastDiscovery _discovery;
  bool _isCasting = false;
  bool _isServerStarted = false;

  @override
  void initState() {
    super.initState();
    _startHarness();
  }

  Future<void> _startHarness() async {
    await _mockServer.start();
    await E2ELocalMediaServer.ensureStarted();

    _discovery = E2EFakeCastDiscovery(
      device: CastDevice(
        id: 'e2e-tv',
        name: 'E2E TV',
        host: '127.0.0.1',
        port: _mockServer.port,
      ),
    );

    _castExtension = BetterPlayerCastExtension(
      contextProvider: () => context,
      discovery: _discovery,
      socketFactory:
          ({
            required host,
            required port,
            timeout = const Duration(seconds: 10),
          }) async {
            return E2ECastTcpSocket.connect(
              host: host,
              port: port,
              timeout: timeout,
            );
          },
    );

    _controller = BetterPlayerController(
      PlayerConfiguration(
        autoPlay: true,
        looping: true,
        controlsConfiguration: const PlayerControlsConfiguration(
          playerTheme: PlayerTheme.material,
          controlsHideTime: Duration(days: 30),
        ),
        extensions: [_castExtension],
      ),
    );

    _castExtension.castingStream.listen((isCasting) {
      if (mounted) {
        setState(() {
          _isCasting = isCasting;
        });
      }
    });

    final dataSource = PlayerDataSource(
      DataSourceType.network,
      E2ELocalMediaServer.mp4Url,
      notificationConfiguration: const NotificationConfiguration(
        showNotification: true,
        title: 'Cast E2E Video',
        author: 'Better Player',
      ),
    );

    await _controller.setupDataSource(dataSource);

    if (mounted) {
      setState(() {
        _isServerStarted = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mockServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isServerStarted) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cast E2E Page'),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _controller),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<String>>(
            valueListenable: _mockServer.receivedCommands,
            builder: (context, commands, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_isCasting)
                    Semantics(
                      identifier: 'e2e_cast_state_connected',
                      container: true,
                      child: const Chip(label: Text('Cast: Connected')),
                    )
                  else
                    Semantics(
                      identifier: 'e2e_cast_state_disconnected',
                      container: true,
                      child: const Chip(label: Text('Cast: Disconnected')),
                    ),
                  if (commands.contains('LOAD'))
                    Semantics(
                      identifier: 'e2e_cast_cmd_load_verified',
                      container: true,
                      child: const Chip(label: Text('Command: LOAD Verified')),
                    ),
                  if (commands.contains('PAUSE'))
                    Semantics(
                      identifier: 'e2e_cast_cmd_pause_verified',
                      container: true,
                      child: const Chip(label: Text('Command: PAUSE Verified')),
                    ),
                  if (commands.contains('STOP'))
                    Semantics(
                      identifier: 'e2e_cast_cmd_stop_verified',
                      container: true,
                      child: const Chip(label: Text('Command: STOP Verified')),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
