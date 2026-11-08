import 'dart:async';

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
  bool _isMuted = false;
  final Map<int, bool> _likedMap = {};
  final Map<int, int> _likeCountMap = {
    0: 32400,
    1: 18900,
    2: 45200,
    3: 89400,
    4: 12100,
    5: 24300,
    6: 67800,
  };

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

  static const List<String> _descriptions = [
    'Action showcase with high dynamic range streaming and instant playback.',
    'Scenic nature journey with dynamic camera panning and caching enabled.',
    'Open-source 3D animated sci-fi short film produced by Blender Institute.',
    'Classic open movie project featuring high-resolution animation.',
    'Native vertical 9:16 portrait video format designed for mobile feeds.',
    'Fast-paced short-form video clip optimized for pre-buffering.',
    'Adaptive HTTP Live Streaming (HLS) with multi-bitrate track switching.',
  ];

  @override
  void initState() {
    super.initState();
    _feedController = BetterPlayerFeedController(
      dataSources: _dataSources,
      poolConfiguration: const PlayerPoolConfiguration(
        playerConfiguration: PlayerConfiguration(
          autoDispose: false,
          handleLifecycle: false,
          fit: BoxFit.cover,
          controlsConfiguration: PlayerControlsConfiguration(
            showControls: false,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    final activeController = _feedController.activeController;
    if (activeController != null) {
      unawaited(activeController.setVolume(_isMuted ? 0 : 1));
    }
  }

  void _toggleLike(int index) {
    setState(() {
      final isLiked = _likedMap[index] ?? false;
      _likedMap[index] = !isLiked;
      final currentLikes = _likeCountMap[index] ?? 1000;
      _likeCountMap[index] = isLiked ? currentLikes - 1 : currentLikes + 1;
    });
  }

  void _onCommentPressed(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _FeedCommentsSheet(),
    );
  }

  void _onSharePressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video link copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _FeedResponsiveContainer(
        feedController: _feedController,
        child: _FeedCardStack(
          feedController: _feedController,
          titles: _titles,
          descriptions: _descriptions,
          totalItems: _dataSources.length,
          isMuted: _isMuted,
          likedMap: _likedMap,
          likeCountMap: _likeCountMap,
          onToggleMute: _toggleMute,
          onToggleLike: _toggleLike,
          onCommentPressed: () => _onCommentPressed(context),
          onSharePressed: () => _onSharePressed(context),
        ),
      ),
    );
  }
}

class _FeedResponsiveContainer extends StatelessWidget {
  const _FeedResponsiveContainer({
    required this.feedController,
    required this.child,
  });

  final BetterPlayerFeedController feedController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 680) {
          return ColoredBox(
            color: const Color(0xFF101014),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 420,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    ),
                    const SizedBox(width: 24),
                    _FeedDesktopNavButtons(feedController: feedController),
                  ],
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}

class _FeedDesktopNavButtons extends StatelessWidget {
  const _FeedDesktopNavButtons({
    required this.feedController,
  });

  final BetterPlayerFeedController feedController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: feedController,
      builder: (context, _) {
        final canGoUp = feedController.currentIndex > 0;
        final canGoDown =
            feedController.currentIndex < feedController.dataSources.length - 1;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FeedNavCircleButton(
              icon: Icons.keyboard_arrow_up_rounded,
              tooltip: 'Previous Video',
              onPressed: canGoUp ? feedController.previous : null,
            ),
            const SizedBox(height: 16),
            _FeedNavCircleButton(
              icon: Icons.keyboard_arrow_down_rounded,
              tooltip: 'Next Video',
              onPressed: canGoDown ? feedController.next : null,
            ),
          ],
        );
      },
    );
  }
}

class _FeedNavCircleButton extends StatelessWidget {
  const _FeedNavCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.white24,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedCardStack extends StatelessWidget {
  const _FeedCardStack({
    required this.feedController,
    required this.titles,
    required this.descriptions,
    required this.totalItems,
    required this.isMuted,
    required this.likedMap,
    required this.likeCountMap,
    required this.onToggleMute,
    required this.onToggleLike,
    required this.onCommentPressed,
    required this.onSharePressed,
  });

  final BetterPlayerFeedController feedController;
  final List<String> titles;
  final List<String> descriptions;
  final int totalItems;
  final bool isMuted;
  final Map<int, bool> likedMap;
  final Map<int, int> likeCountMap;
  final VoidCallback onToggleMute;
  final void Function(int index) onToggleLike;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BetterPlayerFeed(
          controller: feedController,
          configuration: PlayerFeedConfiguration(
            placeholderBuilder: (context, index, dataSource) {
              return _FeedItemPlaceholder(
                title: titles[index % titles.length],
              );
            },
          ),
        ),
        _FeedInteractiveTouchLayer(
          feedController: feedController,
          onDoubleTapLike: () => onToggleLike(feedController.currentIndex),
        ),
        const _FeedGradientScrim(),
        Positioned(
          left: 16,
          bottom: 24,
          right: 76,
          child: _FeedMetaInfoOverlay(
            feedController: feedController,
            titles: titles,
            descriptions: descriptions,
            totalItems: totalItems,
          ),
        ),
        Positioned(
          right: 12,
          bottom: 32,
          child: ListenableBuilder(
            listenable: feedController,
            builder: (context, _) {
              final index = feedController.currentIndex;
              final isLiked = likedMap[index] ?? false;
              final likeCount = likeCountMap[index] ?? 32400;

              return _FeedSideActionsColumn(
                isLiked: isLiked,
                likeCount: likeCount,
                isMuted: isMuted,
                onLikeTapped: () => onToggleLike(index),
                onCommentTapped: onCommentPressed,
                onShareTapped: onSharePressed,
                onMuteTapped: onToggleMute,
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _FeedProgressBar(feedController: feedController),
        ),
      ],
    );
  }
}

class _FeedInteractiveTouchLayer extends StatefulWidget {
  const _FeedInteractiveTouchLayer({
    required this.feedController,
    required this.onDoubleTapLike,
  });

  final BetterPlayerFeedController feedController;
  final VoidCallback onDoubleTapLike;

  @override
  State<_FeedInteractiveTouchLayer> createState() =>
      _FeedInteractiveTouchLayerState();
}

class _FeedInteractiveTouchLayerState
    extends State<_FeedInteractiveTouchLayer> {
  bool _showPlayIndicator = false;
  bool _showHeartAnimation = false;

  void _onSingleTap() {
    widget.feedController.togglePlay();
    setState(() {
      _showPlayIndicator = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showPlayIndicator = false;
        });
      }
    });
  }

  void _onDoubleTap() {
    widget.onDoubleTapLike();
    setState(() {
      _showHeartAnimation = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onSingleTap,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_showPlayIndicator)
            ListenableBuilder(
              listenable: widget.feedController,
              builder: (context, _) {
                final isPlaying = widget.feedController.isPlaying;
                return AnimatedOpacity(
                  opacity: _showPlayIndicator ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          if (_showHeartAnimation)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.3),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 84,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedGradientScrim extends StatelessWidget {
  const _FeedGradientScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black45,
              Colors.transparent,
              Colors.transparent,
              Colors.black87,
            ],
            stops: [0.0, 0.18, 0.55, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _FeedMetaInfoOverlay extends StatelessWidget {
  const _FeedMetaInfoOverlay({
    required this.feedController,
    required this.titles,
    required this.descriptions,
    required this.totalItems,
  });

  final BetterPlayerFeedController feedController;
  final List<String> titles;
  final List<String> descriptions;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: feedController,
      builder: (context, _) {
        final index = feedController.currentIndex;
        final title = titles[index % titles.length];
        final description = descriptions[index % descriptions.length];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FeedPoolBadge(
              currentIndex: index,
              totalItems: totalItems,
              poolSize: feedController.pool.poolSize,
            ),
            const SizedBox(height: 10),
            const _FeedAuthorRow(),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
                shadows: [
                  Shadow(blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _FeedAudioTicker(title: title),
          ],
        );
      },
    );
  }
}

class _FeedPoolBadge extends StatelessWidget {
  const _FeedPoolBadge({
    required this.currentIndex,
    required this.totalItems,
    required this.poolSize,
  });

  final int currentIndex;
  final int totalItems;
  final int poolSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Item ${currentIndex + 1} of $totalItems • $poolSize Leased Slots',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedAuthorRow extends StatelessWidget {
  const _FeedAuthorRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            color: Colors.indigoAccent,
          ),
          child: const Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '@betterplayer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.verified_rounded,
          color: Colors.blueAccent,
          size: 14,
        ),
      ],
    );
  }
}

class _FeedAudioTicker extends StatelessWidget {
  const _FeedAudioTicker({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.music_note_rounded,
          color: Colors.white70,
          size: 14,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Original Audio • $title',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedSideActionsColumn extends StatelessWidget {
  const _FeedSideActionsColumn({
    required this.isLiked,
    required this.likeCount,
    required this.isMuted,
    required this.onLikeTapped,
    required this.onCommentTapped,
    required this.onShareTapped,
    required this.onMuteTapped,
  });

  final bool isLiked;
  final int likeCount;
  final bool isMuted;
  final VoidCallback onLikeTapped;
  final VoidCallback onCommentTapped;
  final VoidCallback onShareTapped;
  final VoidCallback onMuteTapped;

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FeedActionButton(
          icon: isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          iconColor: isLiked ? Colors.redAccent : Colors.white,
          label: _formatNumber(likeCount),
          onPressed: onLikeTapped,
        ),
        const SizedBox(height: 18),
        _FeedActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: Colors.white,
          label: '412',
          onPressed: onCommentTapped,
        ),
        const SizedBox(height: 18),
        _FeedActionButton(
          icon: Icons.share_rounded,
          iconColor: Colors.white,
          label: 'Share',
          onPressed: onShareTapped,
        ),
        const SizedBox(height: 18),
        _FeedActionButton(
          icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          iconColor: isMuted ? Colors.white54 : Colors.white,
          label: isMuted ? 'Muted' : 'Sound',
          onPressed: onMuteTapped,
        ),
      ],
    );
  }
}

class _FeedActionButton extends StatelessWidget {
  const _FeedActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.black.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedProgressBar extends StatefulWidget {
  const _FeedProgressBar({
    required this.feedController,
  });

  final BetterPlayerFeedController feedController;

  @override
  State<_FeedProgressBar> createState() => _FeedProgressBarState();
}

class _FeedProgressBarState extends State<_FeedProgressBar> {
  Timer? _progressTimer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final controller = widget.feedController.activeController;
      final videoPlayerValue = controller?.videoPlayerValue;
      if (videoPlayerValue != null &&
          videoPlayerValue.initialized &&
          videoPlayerValue.duration != null &&
          videoPlayerValue.duration!.inMilliseconds > 0) {
        final currentMs = videoPlayerValue.position.inMilliseconds;
        final totalMs = videoPlayerValue.duration!.inMilliseconds;
        final newProgress = (currentMs / totalMs).clamp(0.0, 1.0);
        if (mounted && (_progress - newProgress).abs() > 0.01) {
          setState(() {
            _progress = newProgress;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: _progress,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _FeedCommentsSheet extends StatelessWidget {
  const _FeedCommentsSheet();

  static const List<Map<String, String>> _sampleComments = [
    {
      'author': 'flutter_dev',
      'text': 'The controller pool is insanely smooth! No playback stutter.',
      'time': '2h ago',
      'likes': '24',
    },
    {
      'author': 'mobile_coder',
      'text': 'Love the pre-caching support. Instant playback on swipe!',
      'time': '4h ago',
      'likes': '12',
    },
    {
      'author': 'jakub_fan',
      'text': 'Better Player is miles ahead of basic video_player.',
      'time': '1d ago',
      'likes': '89',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments (3)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sampleComments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final comment = _sampleComments[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.indigoAccent,
                      child: Text(
                        comment['author']![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '@${comment['author']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment['time']!,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment['text']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                        Text(
                          comment['likes']!,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.greenAccent,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
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
