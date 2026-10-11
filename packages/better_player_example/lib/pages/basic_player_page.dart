import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class BasicPlayerPage extends StatefulWidget {
  const BasicPlayerPage({super.key});

  @override
  _BasicPlayerPageState createState() => _BasicPlayerPageState();
}

class _BasicPlayerPageState extends State<BasicPlayerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Player')),
      body: DemoContainer(
        child: ListView(
          children: [
            const DemoHeader(
              title: 'Convenience Factory Methods',
              description:
                  'Instantiate players quickly with BetterPlayer.network() and '
                  'BetterPlayer.file() without manual controller setup.',
              icon: Icons.flash_on_outlined,
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer.network(Constants.bugBuckBunnyVideoUrl),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Local File Playback (BetterPlayer.file)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (kIsWeb)
              const PlatformNoteCard(
                title: 'Local Files Unavailable on Web',
                message:
                    'Browsers run in a sandbox without direct filesystem access. '
                    'Use BetterPlayer.network() or memory data sources on Web.',
                icon: Icons.folder_off_outlined,
              )
            else
              FutureBuilder<String>(
                future: Utils.getFileUrl(Constants.fileTestVideoUrl),
                builder: (context, snapshot) {
                  if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: BetterPlayer.file(snapshot.data!),
                    );
                  } else {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
