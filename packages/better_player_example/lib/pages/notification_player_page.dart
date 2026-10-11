import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class NotificationPlayerPage extends StatefulWidget {
  const NotificationPlayerPage({super.key});

  @override
  _NotificationPlayerPageState createState() => _NotificationPlayerPageState();
}

class _NotificationPlayerPageState extends State<NotificationPlayerPage> {
  late BetterPlayerController _betterPlayerController;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _setupDataSource();
  }

  Future<void> _setupDataSource() async {
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
      notificationConfiguration: NotificationConfiguration(
        showNotification: true,
        title: 'Elephant Dream',
        author: 'Blender Foundation',
        imageUrl: Constants.catImageUrl,
      ),
    );
    await _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Notification')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'System Notification Controls',
                description:
                    'Publishes playback metadata and transport controls (play/pause/seek) '
                    'to the OS lock screen and status notification bar.',
                instructions:
                    'Start playback and lock device or pull down notification drawer.',
                icon: Icons.notifications_active_outlined,
              ),
              if (!_isMobile)
                const PlatformNoteCard(
                  title: 'Mobile-Only Feature',
                  message:
                      'Lock screen and system notification drawer media controls '
                      'are supported on Android and iOS. They do not appear on Desktop or Web.',
                ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
