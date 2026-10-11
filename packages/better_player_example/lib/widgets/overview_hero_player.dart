import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:material_ui/material_ui.dart';

/// Top hero component on the overview screen displaying a live, muted preview player
/// and a concise usage snippet.
class OverviewHeroPlayer extends StatefulWidget {
  const OverviewHeroPlayer({super.key});

  @override
  State<OverviewHeroPlayer> createState() => _OverviewHeroPlayerState();
}

class _OverviewHeroPlayerState extends State<OverviewHeroPlayer> {
  late final BetterPlayerController _controller;

  @override
  void initState() {
    super.initState();
    const configuration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.bugBuckBunnyVideoUrl,
    );
    _controller = BetterPlayerController(
      configuration,
      betterPlayerDataSource: dataSource,
    );
    _controller.setVolume(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 560,
            maxHeight: 315,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BetterPlayer(controller: _controller),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Production-grade video playback in one widget.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    )
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    "BetterPlayer.network('https://example.com/video.mp4')",
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
