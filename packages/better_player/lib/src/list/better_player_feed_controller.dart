import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:material_ui/material_ui.dart';

/// Controller coordinating data sources, active viewport indices, and
/// [BetterPlayerPool] allocations for a [BetterPlayerFeed].
class BetterPlayerFeedController extends ChangeNotifier {
  /// Creates a feed controller with the given list of [dataSources].
  BetterPlayerFeedController({
    required List<PlayerDataSource> dataSources,
    BetterPlayerPool? pool,
    PlayerPoolConfiguration? poolConfiguration,
    PageController? pageController,
    String Function(int index)? idGetter,
    this.autoPlay = true,
  }) : _dataSources = List.of(dataSources),
       _pool =
           pool ??
           BetterPlayerPool(
             configuration:
                 poolConfiguration ?? const PlayerPoolConfiguration(),
           ),
       _ownsPool = pool == null,
       _pageController = pageController ?? PageController(),
       _idGetter = idGetter ?? ((index) => 'item_$index') {
    _initNotifiers();
  }

  final List<PlayerDataSource> _dataSources;
  final BetterPlayerPool _pool;
  final bool _ownsPool;
  final PageController _pageController;
  final String Function(int index) _idGetter;

  int _currentIndex = 0;
  final Map<int, ValueNotifier<PlayerPoolLease?>> _leaseNotifiers = {};
  bool _isDisposed = false;

  /// Underlying player pool.
  BetterPlayerPool get pool => _pool;

  /// Page controller for PageView feeds.
  PageController get pageController => _pageController;

  /// Current active index in the feed.
  int get currentIndex => _currentIndex;

  /// Whether active items should play automatically.
  final bool autoPlay;

  /// All data sources in the feed.
  List<PlayerDataSource> get dataSources => List.unmodifiable(_dataSources);

  void _initNotifiers() {
    for (var i = 0; i < _dataSources.length; i++) {
      _leaseNotifiers[i] = ValueNotifier<PlayerPoolLease?>(null);
    }
  }

  /// Returns the notifier for a specific feed index.
  ValueNotifier<PlayerPoolLease?> getLeaseNotifier(int index) {
    return _leaseNotifiers.putIfAbsent(
      index,
      () => ValueNotifier<PlayerPoolLease?>(null),
    );
  }

  /// Focuses a new index, acquires a lease for it, triggers lookahead
  /// preloading, and releases out-of-range leases.
  Future<void> onIndexChanged(int index) async {
    if (_isDisposed || index < 0 || index >= _dataSources.length) {
      return;
    }

    final previousIndex = _currentIndex;
    _currentIndex = index;
    _pool.setActiveIndex(index);
    notifyListeners();

    // Pause the previously active controller to prevent overlapping audio
    if (previousIndex != index) {
      final prevLease = _leaseNotifiers[previousIndex]?.value;
      if (prevLease != null &&
          (prevLease.controller.isVideoInitialized() ?? false)) {
        unawaited(prevLease.controller.pause().catchError((_) {}));
      }
    }

    // Acquire lease for active item
    final activeId = _idGetter(index);
    final activeDataSource = _dataSources[index];

    try {
      final lease = await _pool.acquire(
        itemId: activeId,
        index: index,
        dataSource: activeDataSource,
      );

      if (!_isDisposed && _currentIndex == index) {
        getLeaseNotifier(index).value = lease;
        if (autoPlay && (lease.controller.isVideoInitialized() ?? false)) {
          unawaited(lease.controller.setVolume(1));
          unawaited(lease.controller.play());
        }
      }
    } catch (_) {}

    // Update lookahead/lookbehind preloads
    _pool.updatePreloads(
      currentIndex: index,
      dataSources: _dataSources,
      idGetter: _idGetter,
    );
  }

  /// Appends more data sources to the feed (for infinite pagination).
  void appendDataSources(List<PlayerDataSource> newSources) {
    if (_isDisposed || newSources.isEmpty) {
      return;
    }
    final startIndex = _dataSources.length;
    _dataSources.addAll(newSources);

    for (var i = 0; i < newSources.length; i++) {
      _leaseNotifiers[startIndex + i] = ValueNotifier<PlayerPoolLease?>(null);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    for (final notifier in _leaseNotifiers.values) {
      notifier.value?.release();
      notifier.dispose();
    }
    _leaseNotifiers.clear();

    if (_ownsPool) {
      _pool.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }
}
