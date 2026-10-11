import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
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

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.forBiggerBlazesUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.addEventsListener(_onPlayerEvent);
    super.initState();
  }

  void _onPlayerEvent(PlayerEvent event) {
    if (event.betterPlayerEventType == PlayerEventType.hideFullscreen) {
      if (MediaQuery.of(context).orientation == Orientation.landscape) {
        _isManualExit = true;
      }
    }
  }

  @override
  void dispose() {
    _betterPlayerController.removeEventsListener(_onPlayerEvent);
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Fullscreen on Rotation')),
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
            child: DemoContainer(
              child: Column(
                children: [
                  const DemoHeader(
                    title: 'Device Rotation Fullscreen Trigger',
                    description:
                        'Transitions into fullscreen when device rotates to '
                        'landscape, and restores portrait layout on return.',
                    instructions:
                        'Rotate device or simulator to landscape to test auto fullscreen.',
                    icon: Icons.screen_rotation_outlined,
                  ),
                  if (!_isMobile)
                    const PlatformNoteCard(
                      title: 'Mobile-Only Feature',
                      message:
                          'Physical device rotation sensors apply to mobile devices. '
                          'On desktop and web, resize the window to trigger orientation changes.',
                    ),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _betterPlayerController),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
