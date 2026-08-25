import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:material_ui/material_ui.dart';

class AutoFullscreenOnRotationExamplePage extends StatefulWidget {
  const AutoFullscreenOnRotationExamplePage({super.key});

  @override
  _AutoFullscreenOnRotationExamplePageState createState() =>
      _AutoFullscreenOnRotationExamplePageState();
}

class _AutoFullscreenOnRotationExamplePageState
    extends State<AutoFullscreenOnRotationExamplePage> {
  late BetterPlayerController _betterPlayerController;
  Orientation? _lastOrientation;
  bool _isManualExit = false;

  @override
  void initState() {
    const betterPlayerConfiguration = BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.forBiggerBlazesUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.addEventsListener(_onPlayerEvent);
    super.initState();
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.hideFullscreen) {
      if (MediaQuery.of(context).orientation == Orientation.landscape) {
        _isManualExit = true;
      }
    }
  }

  @override
  void dispose() {
    _betterPlayerController.removeEventsListener(_onPlayerEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto fullscreen on rotation')),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (_lastOrientation != null && _lastOrientation != orientation) {
            if (orientation == Orientation.landscape) {
              if (!_betterPlayerController.isFullScreen && !_isManualExit) {
                Future.delayed(Duration.zero, () {
                  _betterPlayerController.enterFullScreen();
                });
              }
            } else if (orientation == Orientation.portrait) {
              _isManualExit = false;
              if (_betterPlayerController.isFullScreen) {
                Future.delayed(Duration.zero, () {
                  _betterPlayerController.exitFullScreen();
                });
              }
            }
          }
          _lastOrientation = orientation;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'This example shows how to automatically enter fullscreen mode '
                    'when rotating the device to landscape and exit when rotating '
                    'back to portrait, using OrientationBuilder.',
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
        },
      ),
    );
  }
}
