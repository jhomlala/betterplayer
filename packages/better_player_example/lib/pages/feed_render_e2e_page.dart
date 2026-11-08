import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils/e2e_local_media_server.dart';
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
        PlayerDataSource.network(
          E2ELocalMediaServer.isRunning
              ? E2ELocalMediaServer.mp4Url
              : Constants.exampleResolutionsUrls['LOW']!,
        ),
        PlayerDataSource.network(
          E2ELocalMediaServer.isRunning
              ? E2ELocalMediaServer.secondaryMp4Url
              : 'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4',
        ),
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

  BetterPlayerController? _currentController;
  void Function(PlayerEvent)? _currentEventListener;
  VoidCallback? _pendingNotifierCleanup;

  void _cleanupFeedListeners() {
    if (_currentController != null && _currentEventListener != null) {
      _currentController!.removeEventsListener(_currentEventListener!);
      _currentController = null;
      _currentEventListener = null;
    }
    _pendingNotifierCleanup?.call();
    _pendingNotifierCleanup = null;
  }

  void _onFeedChanged() {
    _cleanupFeedListeners();
    final index = _feedController.currentIndex;
    final notifier = _feedController.leaseNotifier(index);

    void bindController(BetterPlayerController controller) {
      if (!mounted) return;
      _currentController = controller;
      if (controller.videoPlayerValue?.isPlaying ?? false) {
        _playingIndex.value = index;
      }
      void onEvent(PlayerEvent event) {
        if (!mounted) return;
        if (event.betterPlayerEventType == PlayerEventType.play ||
            (event.betterPlayerEventType == PlayerEventType.progress &&
                (controller.videoPlayerValue?.isPlaying ?? false))) {
          _playingIndex.value = index;
        }
      }

      _currentEventListener = onEvent;
      controller.addEventsListener(onEvent);
    }

    if (notifier.value?.controller != null) {
      bindController(notifier.value!.controller);
    } else {
      void onNotifier() {
        if (notifier.value?.controller != null) {
          notifier.removeListener(onNotifier);
          _pendingNotifierCleanup = null;
          bindController(notifier.value!.controller);
        }
      }

      _pendingNotifierCleanup = () => notifier.removeListener(onNotifier);
      notifier.addListener(onNotifier);
    }
  }

  @override
  void dispose() {
    _cleanupFeedListeners();
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
          Positioned(
            top: 48,
            right: 8,
            child: Semantics(
              identifier: 'better_player_e2e_feed_next_button',
              label: 'Next',
              button: true,
              container: true,
              child: ElevatedButton(
                onPressed: () async {
                  if (_feedController.pageController.hasClients) {
                    _feedController.pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                  await _feedController.onIndexChanged(1);
                },
                child: const Text('Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
