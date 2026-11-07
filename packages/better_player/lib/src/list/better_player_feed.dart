import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

/// Internal item widget rendered inside [BetterPlayerFeed].
class _BetterPlayerFeedItem extends StatefulWidget {
  /// Creates a feed item widget.
  const _BetterPlayerFeedItem({
    required this.index,
    required this.entry,
    required this.controller,
    required this.configuration,
    super.key,
  });

  /// Index of the item in the feed.
  final int index;

  /// Underlying feed entry.
  final PlayerFeedEntry entry;

  /// Feed controller.
  final BetterPlayerFeedController controller;

  /// Feed configuration.
  final PlayerFeedConfiguration configuration;

  @override
  State<_BetterPlayerFeedItem> createState() => _BetterPlayerFeedItemState();
}

class _BetterPlayerFeedItemState extends State<_BetterPlayerFeedItem> {
  bool _firstFrameRendered = false;
  PlayerPoolLease? _currentLease;
  late ValueNotifier<PlayerPoolLease?> _leaseNotifier;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _leaseNotifier = widget.entry.leaseNotifier;
    _leaseNotifier.addListener(_onLeaseChanged);
    _attachLease(_leaseNotifier.value);
  }

  @override
  void didUpdateWidget(_BetterPlayerFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry ||
        oldWidget.controller != widget.controller) {
      _leaseNotifier.removeListener(_onLeaseChanged);
      _leaseNotifier = widget.entry.leaseNotifier;
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
      _errorMessage = lease?.errorMessage;

      if (lease != null) {
        lease.controller.addEventsListener(_onPlayerEvent);
        if (lease.controller.videoPlayerValue?.initialized ?? false) {
          _firstFrameRendered = true;
        }
        if (lease.controller.videoPlayerValue?.hasError ?? false) {
          _errorMessage =
              lease.controller.videoPlayerValue?.errorDescription ??
              lease.errorMessage;
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
    } else if (event.betterPlayerEventType == PlayerEventType.exception) {
      if (mounted) {
        final error =
            event.parameters?['exception'] as String? ??
            _currentLease?.controller.videoPlayerValue?.errorDescription;
        setState(() {
          _errorMessage = error;
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
    final dataSource = widget.entry.dataSource;
    final lease = _currentLease;
    final hasError = (lease?.hasError ?? false) || _errorMessage != null;
    final displayError = _errorMessage ?? lease?.errorMessage;

    if (hasError) {
      if (widget.configuration.errorBuilder != null) {
        return widget.configuration.errorBuilder!(
          context,
          widget.index,
          dataSource,
          displayError,
        );
      }
      return PlayerFeedErrorView(
        errorMessage: displayError,
        translations: lease?.controller.translations,
        onRetry: () => unawaited(widget.controller.retry(index: widget.index)),
      );
    }

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
            key: ValueKey('feed_player_${widget.entry.id}'),
            controller: lease.controller,
          ),
      ],
    );
  }
}

/// High-performance scrollable video feed widget using a bounded [BetterPlayerPool].
/// Supports full-screen vertical swipe feeds and scrolling lists.
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
    if (!widget.configuration.autoPlay && widget.controller.autoPlay) {
      widget.controller.autoPlay = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.controller.entries.isNotEmpty &&
          widget.controller
                  .getLeaseNotifier(widget.controller.currentIndex)
                  .value ==
              null) {
        widget.controller.onIndexChanged(widget.controller.currentIndex);
      }
    });
  }

  @override
  void didUpdateWidget(BetterPlayerFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configuration.autoPlay != widget.configuration.autoPlay) {
      widget.controller.autoPlay = widget.configuration.autoPlay;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return PageView.builder(
          controller: widget.controller.pageController,
          scrollDirection: widget.configuration.scrollDirection,
          itemCount: widget.controller.entries.length,
          findChildIndexCallback: (key) {
            if (key is ValueKey<String>) {
              final id = key.value;
              final entries = widget.controller.entries;
              for (var i = 0; i < entries.length; i++) {
                if (entries[i].id == id) {
                  return i;
                }
              }
            }
            return null;
          },
          onPageChanged: (index) {
            widget.controller.onIndexChanged(index);
          },
          itemBuilder: (context, index) {
            final entry = widget.controller.entries[index];
            return _BetterPlayerFeedItem(
              key: ValueKey(entry.id),
              index: index,
              entry: entry,
              controller: widget.controller,
              configuration: widget.configuration,
            );
          },
        );
      },
    );
  }
}
