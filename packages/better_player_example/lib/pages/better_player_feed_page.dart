import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:material_ui/material_ui.dart';

class BetterPlayerFeedPage extends StatefulWidget {
  const BetterPlayerFeedPage({super.key});

  @override
  State<BetterPlayerFeedPage> createState() => _BetterPlayerFeedPageState();
}

class _BetterPlayerFeedPageState extends State<BetterPlayerFeedPage> {
  late final BetterPlayerFeedController _feedController;

  static final List<PlayerDataSource> _dataSources = [
    PlayerDataSource.network(
      Constants.forBiggerBlazesUrl,
      cacheConfiguration: const CacheConfiguration(useCache: true),
    ),
    PlayerDataSource.network(
      Constants.forBiggerJoyridesVideoUrl,
      cacheConfiguration: const CacheConfiguration(useCache: true),
    ),
    PlayerDataSource.network(
      Constants.elephantDreamVideoUrl,
      cacheConfiguration: const CacheConfiguration(useCache: true),
    ),
    PlayerDataSource.network(
      Constants.bugBuckBunnyVideoUrl,
      cacheConfiguration: const CacheConfiguration(useCache: true),
    ),
    PlayerDataSource.network(
      Constants.verticalVideoUrl,
      cacheConfiguration: const CacheConfiguration(useCache: true),
    ),
    PlayerDataSource.network(
      Constants.phantomVideoUrl,
      cacheConfiguration: const CacheConfiguration(useCache: true),
    ),
    PlayerDataSource.network(
      Constants.hlsTestStreamUrl,
      videoFormat: VideoFormat.hls,
    ),
  ];

  static const List<String> _titles = [
    'For Bigger Blazes (Action)',
    'For Bigger Joyrides (Nature)',
    'Elephants Dream (MP4)',
    'Big Buck Bunny (Classic)',
    'Vertical Reframe (9:16 Portrait)',
    'Phantom Bunny (Shorts)',
    'Mux Adaptive Stream (HLS)',
  ];

  @override
  void initState() {
    super.initState();
    _feedController = BetterPlayerFeedController(
      dataSources: _dataSources,
    );
  }

  @override
  void dispose() {
    _feedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Video Feed (Pool & Preload)',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          BetterPlayerFeed(
            controller: _feedController,
            configuration: PlayerFeedConfiguration(
              placeholderBuilder: (context, index, dataSource) {
                return _FeedItemPlaceholder(
                  title: _titles[index % _titles.length],
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            bottom: 32,
            right: 80,
            child: _FeedItemMetaOverlay(
              feedController: _feedController,
              titles: _titles,
              totalItems: _dataSources.length,
            ),
          ),
          const Positioned(
            right: 16,
            bottom: 40,
            child: _FeedSideActionsOverlay(),
          ),
        ],
      ),
    );
  }
}

class _FeedItemPlaceholder extends StatelessWidget {
  const _FeedItemPlaceholder({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Loading $title...',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItemMetaOverlay extends StatelessWidget {
  const _FeedItemMetaOverlay({
    required this.feedController,
    required this.titles,
    required this.totalItems,
  });

  final BetterPlayerFeedController feedController;
  final List<String> titles;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: feedController,
      builder: (context, _) {
        final currentIndex = feedController.currentIndex;
        final title = titles[currentIndex % titles.length];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Item ${currentIndex + 1} of $totalItems • Pool: 3 Slots',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Swipe up / down. Memory capped by bounded controller pool with distance eviction.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedSideActionsOverlay extends StatelessWidget {
  const _FeedSideActionsOverlay();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FeedActionButton(
          icon: Icons.favorite_border,
          label: '32.4k',
        ),
        SizedBox(height: 16),
        _FeedActionButton(
          icon: Icons.comment_outlined,
          label: '412',
        ),
        SizedBox(height: 16),
        _FeedActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
        ),
      ],
    );
  }
}

class _FeedActionButton extends StatelessWidget {
  const _FeedActionButton({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {},
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
