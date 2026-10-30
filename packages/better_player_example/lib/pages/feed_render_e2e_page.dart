import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:material_ui/material_ui.dart';

/// E2E page for #1632. It mounts a pooled [BetterPlayerFeed] with the same
/// setup as the bug report, so a Maestro flow can screenshot the video area
/// and check that real pixels reach the screen (not only audio).
class FeedRenderE2EPage extends StatefulWidget {
  const FeedRenderE2EPage({super.key});

  @override
  State<FeedRenderE2EPage> createState() => _FeedRenderE2EPageState();
}

class _FeedRenderE2EPageState extends State<FeedRenderE2EPage> {
  late final BetterPlayerFeedController _feedController;
  final ValueNotifier<int> _playingIndex = ValueNotifier<int>(-1);

  @override
  void initState() {
    super.initState();
    _feedController = BetterPlayerFeedController(
      dataSources: [
        PlayerDataSource.network(Constants.exampleResolutionsUrls['LOW']!),
        PlayerDataSource.network(Constants.exampleResolutionsUrls['MEDIUM']!),
      ],
      poolConfiguration: const PlayerPoolConfiguration(
        playerConfiguration: PlayerConfiguration(
          looping: true,
          fit: BoxFit.contain,
          controlsConfiguration: PlayerControlsConfiguration(
            showControls: false,
          ),
        ),
      ),
    );
    _feedController.addListener(_onFeedChanged);
    _onFeedChanged();
  }

  void _onFeedChanged() {
    final index = _feedController.currentIndex;
    final notifier = _feedController.getLeaseNotifier(index);
    void markWhenPlaying() {
      final controller = notifier.value?.controller;
      if (controller == null) {
        return;
      }
      if (controller.isPlaying() ?? false) {
        _playingIndex.value = index;
      }
      controller.addEventsListener((event) {
        if (event.betterPlayerEventType == PlayerEventType.play) {
          _playingIndex.value = index;
        }
      });
    }

    if (notifier.value != null) {
      markWhenPlaying();
    } else {
      void once() {
        notifier.removeListener(once);
        markWhenPlaying();
      }

      notifier.addListener(once);
    }
  }

  @override
  void dispose() {
    _feedController
      ..removeListener(_onFeedChanged)
      ..dispose();
    _playingIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          BetterPlayerFeed(
            controller: _feedController,
            configuration: PlayerFeedConfiguration(
              // Solid black placeholder: a black screenshot means no video.
              placeholderBuilder: (context, index, dataSource) =>
                  const ColoredBox(color: Colors.black),
            ),
          ),
          Positioned(
            top: 48,
            left: 8,
            child: ValueListenableBuilder<int>(
              valueListenable: _playingIndex,
              builder: (context, index, _) {
                final status = index < 0 ? 'waiting' : 'playing_$index';
                return Semantics(
                  identifier: 'better_player_e2e_feed_render_status_$status',
                  label: status,
                  container: true,
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
