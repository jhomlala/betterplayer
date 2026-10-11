import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

/// Item widget rendered inside [BetterPlayerFeed].
class BetterPlayerFeedItem extends StatefulWidget {
  /// Creates a feed item widget.
  const BetterPlayerFeedItem({
    required this.index,
    required this.controller,
    required this.configuration,
    super.key,
  });

  /// Index of the item in the feed.
  final int index;

  /// Feed controller.
  final BetterPlayerFeedController controller;

  /// Feed configuration.
  final PlayerFeedConfiguration configuration;

  @override
  State<BetterPlayerFeedItem> createState() => _BetterPlayerFeedItemState();
}

class _BetterPlayerFeedItemState extends State<BetterPlayerFeedItem> {
  bool _firstFrameRendered = false;
  PlayerPoolLease? _currentLease;
  late ValueNotifier<PlayerPoolLease?> _leaseNotifier;

  @override
  void initState() {
    super.initState();
    _leaseNotifier = widget.controller.getLeaseNotifier(widget.index);
    _leaseNotifier.addListener(_onLeaseChanged);
    _attachLease(_leaseNotifier.value);
  }

  @override
  void didUpdateWidget(BetterPlayerFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.controller != widget.controller) {
      _leaseNotifier.removeListener(_onLeaseChanged);
      _leaseNotifier = widget.controller.getLeaseNotifier(widget.index);
      _leaseNotifier.addListener(_onLeaseChanged);
      _attachLease(_leaseNotifier.value);
    }
  }

  void _onLeaseChanged() {
    if (mounted) {
      setState(() {
        _attachLease(_leaseNotifier.value);
      });
    }
  }

  void _attachLease(PlayerPoolLease? lease) {
    if (_currentLease != lease) {
      _currentLease?.controller.removeEventsListener(_onPlayerEvent);
      _currentLease = lease;
      _firstFrameRendered = false;

      if (lease != null) {
        lease.controller.addEventsListener(_onPlayerEvent);
        if (lease.controller.isVideoInitialized() ?? false) {
          _firstFrameRendered = true;
        }
      }
    }
  }

  void _onPlayerEvent(PlayerEvent event) {
    if (event.betterPlayerEventType == PlayerEventType.initialized) {
      if (mounted && !_firstFrameRendered) {
        setState(() {
          _firstFrameRendered = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _leaseNotifier.removeListener(_onLeaseChanged);
    _currentLease?.controller.removeEventsListener(_onPlayerEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = widget.controller.dataSources[widget.index];
    final lease = _currentLease;
    final showPlayer = lease != null && lease.isValid && _firstFrameRendered;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always display placeholder underneath
        if (widget.configuration.placeholderBuilder != null)
          widget.configuration.placeholderBuilder!(
            context,
            widget.index,
            dataSource,
          )
        else
          const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),

        // Video player on top once the first frame has rendered
        if (showPlayer)
          BetterPlayer(
            key: ValueKey('feed_player_${widget.index}'),
            controller: lease.controller,
          ),
      ],
    );
  }
}

/// High-performance scrollable video feed widget using a bounded [BetterPlayerPool].
/// Supports full-screen TikTok/Reels style vertical feeds and scrolling lists.
class BetterPlayerFeed extends StatefulWidget {
  /// Creates a feed widget with the provided [controller].
  const BetterPlayerFeed({
    required this.controller,
    this.configuration = const PlayerFeedConfiguration(),
    super.key,
  });

  /// The feed controller driving data and leases.
  final BetterPlayerFeedController controller;

  /// Configuration options for the feed.
  final PlayerFeedConfiguration configuration;

  @override
  State<BetterPlayerFeed> createState() => _BetterPlayerFeedState();
}

class _BetterPlayerFeedState extends State<BetterPlayerFeed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.onIndexChanged(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller.pageController,
      scrollDirection: widget.configuration.scrollDirection,
      itemCount: widget.controller.dataSources.length,
      onPageChanged: (index) {
        widget.controller.onIndexChanged(index);
      },
      itemBuilder: (context, index) {
        return BetterPlayerFeedItem(
          index: index,
          controller: widget.controller,
          configuration: widget.configuration,
        );
      },
    );
  }
}
