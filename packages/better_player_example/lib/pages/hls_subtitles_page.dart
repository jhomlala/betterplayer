import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class HlsSubtitlesPage extends StatefulWidget {
  const HlsSubtitlesPage({super.key});

  @override
  _HlsSubtitlesPageState createState() => _HlsSubtitlesPageState();
}

class _HlsSubtitlesPageState extends State<HlsSubtitlesPage> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerController _closedCaptionsController;

  @override
  void initState() {
    const controlsConfiguration = PlayerControlsConfiguration(
      controlBarColor: Colors.black26,
      progressBarPlayedColor: Colors.indigo,
      progressBarHandleColor: Colors.indigo,
      controlBarHeight: 40,
      loadingColor: Colors.red,
      overflowModalColor: Colors.black54,
      overflowModalTextColor: Colors.white,
      overflowMenuIconsColor: Colors.white,
    );

    const betterPlayerConfiguration = PlayerConfiguration(
      controlsConfiguration: controlsConfiguration,
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      subtitlesConfiguration: PlayerSubtitlesConfiguration(
        fontSize: 16,
      ),
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.segmentedSubtitlesHlsUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);

    _closedCaptionsController = BetterPlayerController(
      betterPlayerConfiguration,
    );
    _closedCaptionsController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    _closedCaptionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('HLS Subtitles & Captions')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'HLS Subtitle & Caption Modes',
                description:
                    'Demonstrates segmented WebVTT subtitle playlists alongside '
                    'in-stream closed captions (CEA-608 / CEA-708) parsed directly '
                    'from the HLS manifest.',
                instructions:
                    'Open the overflow menu (three dots) to select subtitle or closed caption tracks.',
                icon: Icons.closed_caption_outlined,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '1. Segmented WebVTT Playlists',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Loads segmented subtitle playlists declared with #EXT-X-MEDIA:TYPE=SUBTITLES '
                  'and synchronizes cues in real time.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '2. In-Stream Closed Captions (CEA-608 / CEA-708)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Auto-discovers #EXT-X-MEDIA:TYPE=CLOSED-CAPTIONS tags in the manifest. '
                  'Decodes cues through native platform engines and displays them with PlayerSubtitlesDrawer.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _closedCaptionsController),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
