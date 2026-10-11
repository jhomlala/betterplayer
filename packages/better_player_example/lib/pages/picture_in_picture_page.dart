import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:material_ui/material_ui.dart';

class PictureInPicturePage extends StatefulWidget {
  const PictureInPicturePage({super.key});

  @override
  _PictureInPicturePageState createState() => _PictureInPicturePageState();
}

class _PictureInPicturePageState extends State<PictureInPicturePage> {
  late BetterPlayerController _betterPlayerController;
  final GlobalKey _betterPlayerKey = GlobalKey();
  bool? _isPipSupported;

  @override
  void initState() {
    super.initState();
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);

    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == PlayerEventType.initialized) {
        _checkPipSupport();
      }
    });
  }

  Future<void> _checkPipSupport() async {
    final supported = await _betterPlayerController
        .isPictureInPictureSupported();
    if (mounted) {
      setState(() {
        _isPipSupported = supported;
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
      appBar: AppBar(title: const Text('Picture in Picture')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Floating PiP Window',
                description:
                    'Enables native Picture in Picture windowing on supported '
                    'platforms so video persists in an overlay window.',
                instructions:
                    'Tap "Enter PiP" or navigate home to minimize video into floating window.',
                icon: Icons.picture_in_picture_alt_outlined,
              ),
              if (_isPipSupported == false)
                const PlatformNoteCard(
                  title: 'PiP Unsupported on This Platform',
                  message:
                      'Picture in Picture is not supported on Windows. '
                      'It is supported on Android, iOS, and Web browsers.',
                  icon: Icons.picture_in_picture_alt_outlined,
                  isWarning: true,
                ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(
                  controller: _betterPlayerController,
                  key: _betterPlayerKey,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.picture_in_picture),
                      label: const Text('Enter PiP'),
                      onPressed: _isPipSupported == false
                          ? null
                          : () {
                              _betterPlayerController.enablePictureInPicture(
                                _betterPlayerKey,
                              );
                            },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close_fullscreen),
                      label: const Text('Exit PiP'),
                      onPressed: _isPipSupported == false
                          ? null
                          : () async {
                              await _betterPlayerController
                                  .disablePictureInPicture();
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
