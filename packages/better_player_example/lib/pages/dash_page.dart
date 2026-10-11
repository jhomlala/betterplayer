import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class DashPage extends StatefulWidget {
  const DashPage({super.key});

  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerController _betterPlayerController2;

  bool get _isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(
      PlayerDataSource(
        DataSourceType.network,
        Constants.dashStreamUrl,
        liveStream: true,
      ),
    );

    _betterPlayerController2 = BetterPlayerController(
      betterPlayerConfiguration,
    );
    _betterPlayerController2.setupDataSource(
      PlayerDataSource(
        DataSourceType.network,
        Constants.dashBigBuckBunnyUrl,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    _betterPlayerController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('DASH Streaming')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Dynamic Adaptive Streaming (DASH)',
                description:
                    'Plays MPEG-DASH (.mpd) manifests with adaptive bitrate switching '
                    'and live stream timeline support.',
                icon: Icons.stream,
              ),
              if (_isApple)
                const PlatformNoteCard(
                  title: 'DASH Not Supported on iOS/macOS',
                  message:
                      'Apple AVPlayer only supports HLS (.m3u8) manifests natively. '
                      'DASH (.mpd) is supported on Android, Windows, and Web.',
                  icon: Icons.warning_amber_rounded,
                  isWarning: true,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '1. Live DASH Stream',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _ResolutionText(controller: _betterPlayerController),
              const SizedBox(height: 6),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '2. VOD DASH Stream (Big Buck Bunny)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _ResolutionText(controller: _betterPlayerController2),
              const SizedBox(height: 6),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController2),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolutionText extends StatefulWidget {
  const _ResolutionText({required this.controller});
  final BetterPlayerController controller;

  @override
  State<_ResolutionText> createState() => _ResolutionTextState();
}

class _ResolutionTextState extends State<_ResolutionText> {
  void _listener() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addVideoListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeVideoListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.videoPlayerValue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Resolution: ${(value?.size?.width ?? 0).toInt()}x${(value?.size?.height ?? 0).toInt()}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
