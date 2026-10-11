import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class AutoFullscreenOrientationPage extends StatefulWidget {
  const AutoFullscreenOrientationPage({super.key});

  @override
  _AutoFullscreenOrientationPageState createState() =>
      _AutoFullscreenOrientationPageState();
}

class _AutoFullscreenOrientationPageState
    extends State<AutoFullscreenOrientationPage> {
  late BetterPlayerController _betterPlayerController;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoDetectFullscreenDeviceOrientation: true,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.forBiggerBlazesUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Orientation on Fullscreen')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            children: [
              const DemoHeader(
                title: 'Aspect-Adaptive Fullscreen Lock',
                description:
                    'Detects video dimensions and locks screen orientation to landscape '
                    'for wide videos or portrait for vertical videos.',
                instructions:
                    'Toggle between horizontal and vertical videos to observe fullscreen adaptation.',
                icon: Icons.screen_lock_rotation_outlined,
              ),
              if (!_isMobile)
                const PlatformNoteCard(
                  title: 'Mobile-Only Feature',
                  message:
                      'Screen orientation lock applies to mobile phones and tablets. '
                      'Desktop monitors and web browsers have fixed aspect ratios.',
                ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.crop_landscape),
                      label: const Text('Play Horizontal (16:9)'),
                      onPressed: () async {
                        final dataSource = PlayerDataSource(
                          DataSourceType.network,
                          Constants.forBiggerBlazesUrl,
                        );
                        await _betterPlayerController.setupDataSource(
                          dataSource,
                        );
                        _betterPlayerController.enterFullScreen();
                      },
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.crop_portrait),
                      label: const Text('Play Vertical (9:16)'),
                      onPressed: () async {
                        final dataSource = PlayerDataSource(
                          DataSourceType.network,
                          Constants.verticalVideoUrl,
                        );
                        await _betterPlayerController.setupDataSource(
                          dataSource,
                        );
                        _betterPlayerController.enterFullScreen();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
