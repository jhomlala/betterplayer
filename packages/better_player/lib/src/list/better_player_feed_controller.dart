import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/logging/player_logger.dart';
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
    bool? autoPlay,
  }) : _pool =
           pool ??
           BetterPlayerPool(
             configuration:
                 poolConfiguration ?? const PlayerPoolConfiguration(),
           ),
       _ownsPool = pool == null,
       _pageController = pageController ?? PageController(),
       _ownsPageController = pageController == null,
       _autoPlay = autoPlay ?? true {
    final effectiveIdGetter = idGetter ?? ((index) => 'item_$index');
    final seenIds = <String>{};
    for (var i = 0; i < dataSources.length; i++) {
      final id = effectiveIdGetter(i);
      if (!seenIds.add(id)) {
        throw ArgumentError('Duplicate feed entry id: $id');
      }
      _entries.add(
        PlayerFeedEntry(
          id: id,
          dataSource: dataSources[i],
        ),
      );
    }
  }

  final List<PlayerFeedEntry> _entries = [];
  final BetterPlayerPool _pool;
  final bool _ownsPool;
  final PageController _pageController;
  final bool _ownsPageController;
  final StreamController<PlayerFeedItemMetrics> _metricsController =
      StreamController<PlayerFeedItemMetrics>.broadcast(sync: true);

  int _currentIndex = 0;
  int _nextIdCounter = 0;
  bool _isDisposed = false;

  // Active metrics tracking state
  String? _activeMetricsItemId;
  int? _activeMetricsIndex;
  bool _activeWasPreloaded = false;
  Stopwatch? _activeStopwatch;
  Duration? _activeTtff;
  int _activeRebufferCount = 0;
  Duration _activeRebufferDuration = Duration.zero;
  Stopwatch? _rebufferStopwatch;
  String? _activeErrorMessage;
  BetterPlayerController? _activeEventController;

  /// Underlying player pool.
  BetterPlayerPool get pool => _pool;

  /// Page controller for PageView feeds.
  PageController get pageController => _pageController;

  /// Current active index in the feed.
  int get currentIndex => _currentIndex;

  bool _autoPlay;

  /// Whether active items should play automatically.
  bool get autoPlay => _autoPlay;
  set autoPlay(bool value) {
    if (_autoPlay != value) {
      _autoPlay = value;
      notifyListeners();
    }
  }

  /// The controller for the currently active feed item, or null if unallocated.
  BetterPlayerController? get activeController {
    if (_currentIndex >= 0 && _currentIndex < _entries.length) {
      return _entries[_currentIndex].leaseNotifier.value?.controller;
    }
    return null;
  }

  /// Whether the currently active video is playing.
  bool get isPlaying => activeController?.isPlaying() ?? false;

  /// Plays the currently active video.
  Future<void> play() async {
    final controller = activeController;
    if (controller != null) {
      await controller.play();
    }
  }

  /// Pauses the currently active video.
  Future<void> pause() async {
    final controller = activeController;
    if (controller != null) {
      await controller.pause();
    }
  }

  /// Toggles play/pause for the currently active video.
  Future<void> togglePlay() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Broadcast stream emitting performance and Quality of Experience (QoE) metrics.
  Stream<PlayerFeedItemMetrics> get metricsStream => _metricsController.stream;

  /// All entries currently in the feed.
  List<PlayerFeedEntry> get entries => List.unmodifiable(_entries);

  /// All data sources in the feed.
  List<PlayerDataSource> get dataSources =>
      _entries.map((entry) => entry.dataSource).toList(growable: false);

  String _generateUniqueId() {
    while (true) {
      final candidate = 'item_${_nextIdCounter++}';
      if (!_hasId(candidate)) {
        return candidate;
      }
    }
  }

  bool _hasId(String id) {
    for (final entry in _entries) {
      if (entry.id == id) {
        return true;
      }
    }
    return false;
  }

  void _reindexPool() {
    final indexById = <String, int>{};
    for (var i = 0; i < _entries.length; i++) {
      indexById[_entries[i].id] = i;
    }
    _pool.reindex(indexById: indexById);
  }

  /// Returns the lease notifier for a specific feed [index].
  ValueNotifier<PlayerPoolLease?> leaseNotifier(int index) {
    if (index >= 0 && index < _entries.length) {
      return _entries[index].leaseNotifier;
    }
    throw RangeError.index(index, _entries, 'index');
  }

  /// Jumps to the feed item at [index], updating playback and scrolling the view.
  void jumpTo(int index) {
    if (index < 0 || index >= _entries.length) {
      return;
    }
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    } else {
      unawaited(onIndexChanged(index));
    }
  }

  /// Advances to the next video in the feed.
  void next() {
    if (_currentIndex + 1 < _entries.length) {
      jumpTo(_currentIndex + 1);
    }
  }

  /// Moves to the previous video in the feed.
  void previous() {
    if (_currentIndex > 0) {
      jumpTo(_currentIndex - 1);
    }
  }

  /// Focuses a new index, acquires a lease for it, triggers lookahead
  /// preloading, and releases out-of-range leases.
  Future<void> onIndexChanged(int index) async {
    if (_isDisposed || index < 0 || index >= _entries.length) {
      return;
    }

    final previousIndex = _currentIndex;
    _currentIndex = index;
    _pool.setActiveIndex(index);
    notifyListeners();

    // Pause the previously active controller to prevent overlapping audio
    if (previousIndex != index && previousIndex < _entries.length) {
      final prevLease = _entries[previousIndex].leaseNotifier.value;
      if (prevLease != null &&
          (prevLease.controller.videoPlayerValue?.initialized ?? false)) {
        unawaited(prevLease.controller.pause().catchError((_) {}));
      }
    }

    _emitActiveMetrics();

    // Acquire lease for active item
    final activeEntry = _entries[index];
    final activeId = activeEntry.id;
    final activeDataSource = activeEntry.dataSource;

    _activeMetricsItemId = activeId;
    _activeMetricsIndex = index;
    _activeStopwatch = Stopwatch()..start();
    _activeTtff = null;
    _activeRebufferCount = 0;
    _activeRebufferDuration = Duration.zero;
    _rebufferStopwatch = null;
    _activeErrorMessage = null;

    try {
      final lease = await _pool.acquire(
        itemId: activeId,
        index: index,
        dataSource: activeDataSource,
      );

      if (!_isDisposed && _currentIndex == index && lease.isValid) {
        final notifier = activeEntry.leaseNotifier;
        notifier.value = lease;
        _activeWasPreloaded = lease.wasPreloaded;

        lease.addEvictionListener(() {
          if (notifier.value == lease) {
            notifier.value = null;
          }
        });

        if (lease.hasError) {
          _activeErrorMessage = lease.errorMessage;
          _emitActiveMetrics();
        } else {
          if (lease.controller.videoPlayerValue?.initialized ?? false) {
            _activeTtff = _activeStopwatch?.elapsed;
          }
          _activeEventController = lease.controller;
          lease.controller.addEventsListener(_onPlayerMetricsEvent);

          if (autoPlay) {
            _startLeasePlayback(lease: lease, index: index);
          }
        }
      }
    } on Object catch (error) {
      if (!_isDisposed) {
        _activeErrorMessage = error.toString();
        _emitActiveMetrics();
        PlayerLogger.error(
          message: 'Error acquiring lease for feed index $index: $error',
        );
      }
    }

    // Update lookahead/lookbehind preloads
    _pool.updatePreloads(
      currentIndex: index,
      dataSources: dataSources,
      idGetter: (i) => _entries[i].id,
    );
  }

  void _onPlayerMetricsEvent(PlayerEvent event) {
    if (_isDisposed) {
      return;
    }
    final type = event.betterPlayerEventType;
    if (type == PlayerEventType.initialized) {
      _activeTtff ??= _activeStopwatch?.elapsed;
    } else if (type == PlayerEventType.bufferingStart) {
      _activeRebufferCount++;
      _rebufferStopwatch = Stopwatch()..start();
    } else if (type == PlayerEventType.bufferingEnd) {
      if (_rebufferStopwatch != null) {
        _activeRebufferDuration += _rebufferStopwatch!.elapsed;
        _rebufferStopwatch = null;
      }
    } else if (type == PlayerEventType.exception) {
      _activeErrorMessage =
          event.parameters?['exception'] as String? ?? 'Playback error';
      _emitActiveMetrics();
    }
  }

  void _emitActiveMetrics() {
    if (_activeMetricsItemId == null) {
      return;
    }

    if (_rebufferStopwatch != null) {
      _activeRebufferDuration += _rebufferStopwatch!.elapsed;
      _rebufferStopwatch = null;
    }

    if (!_metricsController.isClosed) {
      _metricsController.add(
        PlayerFeedItemMetrics(
          itemId: _activeMetricsItemId!,
          index: _activeMetricsIndex ?? 0,
          wasPreloaded: _activeWasPreloaded,
          timeToFirstFrame: _activeTtff,
          rebufferCount: _activeRebufferCount,
          rebufferDuration: _activeRebufferDuration,
          errorMessage: _activeErrorMessage,
        ),
      );
    }

    _activeEventController?.removeEventsListener(_onPlayerMetricsEvent);
    _activeEventController = null;
    _activeMetricsItemId = null;
    _activeMetricsIndex = null;
    _activeStopwatch?.stop();
    _activeStopwatch = null;
    _activeWasPreloaded = false;
  }

  void _startLeasePlayback({
    required PlayerPoolLease lease,
    required int index,
  }) {
    unawaited(lease.controller.setVolume(1));
    unawaited(lease.controller.play());

    if (!(lease.controller.videoPlayerValue?.initialized ?? false)) {
      late final void Function(PlayerEvent) initListener;
      initListener = (event) {
        if (event.betterPlayerEventType == PlayerEventType.initialized) {
          lease.controller.removeEventsListener(initListener);
          if (!_isDisposed && _currentIndex == index && lease.isValid) {
            unawaited(lease.controller.setVolume(1));
            unawaited(lease.controller.play());
          }
        }
      };
      lease.addEvictionListener(() {
        lease.controller.removeEventsListener(initListener);
      });
      lease.controller.addEventsListener(initListener);
    }
  }

  /// Retries loading and binding the feed item at [index] (defaults to [currentIndex]).
  Future<void> retry([int? index]) async {
    final targetIndex = index ?? _currentIndex;
    if (_isDisposed || targetIndex < 0 || targetIndex >= _entries.length) {
      return;
    }
    final entry = _entries[targetIndex];
    final currentLease = entry.leaseNotifier.value;
    entry.leaseNotifier.value = null;
    currentLease?.release();

    if (_currentIndex == targetIndex) {
      await onIndexChanged(targetIndex);
    }
  }

  /// Adds a single [dataSource] to the end of the feed.
  void add(PlayerDataSource dataSource, {String? id}) {
    addAll([dataSource], ids: id != null ? [id] : null);
  }

  /// Appends [sources] to the end of the feed.
  void addAll(
    List<PlayerDataSource> sources, {
    List<String>? ids,
  }) {
    insertAll(index: _entries.length, sources: sources, ids: ids);
  }

  /// Inserts a single [dataSource] at [index].
  void insert({
    required int index,
    required PlayerDataSource dataSource,
    String? id,
  }) {
    insertAll(
      index: index,
      sources: [dataSource],
      ids: id != null ? [id] : null,
    );
  }

  /// Inserts [sources] at [index] with optional custom [ids].
  void insertAll({
    required int index,
    required List<PlayerDataSource> sources,
    List<String>? ids,
  }) {
    if (_isDisposed || sources.isEmpty) {
      return;
    }
    if (index < 0 || index > _entries.length) {
      throw RangeError.range(index, 0, _entries.length, 'index');
    }
    if (ids != null && ids.length != sources.length) {
      throw ArgumentError(
        'ids length (${ids.length}) must match sources length (${sources.length})',
      );
    }

    if (ids != null) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) {
          throw ArgumentError('Duplicate feed entry id in batch: $id');
        }
        if (_hasId(id)) {
          throw ArgumentError('Duplicate feed entry id: $id');
        }
      }
    }

    final newEntries = <PlayerFeedEntry>[];
    for (var i = 0; i < sources.length; i++) {
      final id = ids != null ? ids[i] : _generateUniqueId();
      newEntries.add(
        PlayerFeedEntry(
          id: id,
          dataSource: sources[i],
        ),
      );
    }

    _entries.insertAll(index, newEntries);

    if (index <= _currentIndex) {
      _currentIndex += sources.length;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }

    _reindexPool();
    _pool.updatePreloads(
      currentIndex: _currentIndex,
      dataSources: dataSources,
      idGetter: (i) => _entries[i].id,
    );
    notifyListeners();
  }

  /// Removes the data source at [index].
  Future<void> removeAt(int index) async {
    if (_isDisposed) {
      return;
    }
    if (index < 0 || index >= _entries.length) {
      throw RangeError.index(index, _entries, 'index');
    }

    if (index == _currentIndex) {
      _emitActiveMetrics();
    }

    final removed = _entries.removeAt(index);
    _pool.releaseItem(itemId: removed.id);
    removed.dispose();

    _reindexPool();

    if (_entries.isEmpty) {
      _currentIndex = 0;
      notifyListeners();
      return;
    }

    if (index < _currentIndex) {
      _currentIndex -= 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
      _pool.updatePreloads(
        currentIndex: _currentIndex,
        dataSources: dataSources,
        idGetter: (i) => _entries[i].id,
      );
      notifyListeners();
    } else if (index == _currentIndex) {
      if (_currentIndex >= _entries.length) {
        _currentIndex = _entries.length - 1;
      }
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
      notifyListeners();
      await onIndexChanged(_currentIndex);
    } else {
      _pool.updatePreloads(
        currentIndex: _currentIndex,
        dataSources: dataSources,
        idGetter: (i) => _entries[i].id,
      );
      notifyListeners();
    }
  }

  /// Replaces the data source at [index] with [dataSource].
  Future<void> replace({
    required int index,
    required PlayerDataSource dataSource,
    String? id,
  }) async {
    if (_isDisposed) {
      return;
    }
    if (index < 0 || index >= _entries.length) {
      throw RangeError.index(index, _entries, 'index');
    }

    if (index == _currentIndex) {
      _emitActiveMetrics();
    }

    final oldEntry = _entries[index];
    final effectiveId = id ?? oldEntry.id;
    if (id != null && id != oldEntry.id && _hasId(id)) {
      throw ArgumentError('Duplicate feed entry id: $id');
    }

    _pool.releaseItem(itemId: oldEntry.id);
    oldEntry.dispose();

    final newEntry = PlayerFeedEntry(
      id: effectiveId,
      dataSource: dataSource,
    );
    _entries[index] = newEntry;

    _reindexPool();
    notifyListeners();

    if (index == _currentIndex) {
      await onIndexChanged(index);
    } else {
      _pool.updatePreloads(
        currentIndex: _currentIndex,
        dataSources: dataSources,
        idGetter: (i) => _entries[i].id,
      );
    }
  }

  /// Replaces all data sources in the feed, resetting to [initialIndex].
  Future<void> replaceAll({
    required List<PlayerDataSource> dataSources,
    List<String>? ids,
    int initialIndex = 0,
  }) async {
    if (_isDisposed) {
      return;
    }
    if (ids != null && ids.length != dataSources.length) {
      throw ArgumentError(
        'ids length (${ids.length}) must match dataSources length (${dataSources.length})',
      );
    }

    if (ids != null) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) {
          throw ArgumentError('Duplicate feed entry id in batch: $id');
        }
      }
    }

    _emitActiveMetrics();

    for (final entry in _entries) {
      _pool.releaseItem(itemId: entry.id);
      entry.dispose();
    }
    _entries.clear();
    _nextIdCounter = 0;

    if (dataSources.isEmpty) {
      _currentIndex = 0;
      notifyListeners();
      return;
    }

    for (var i = 0; i < dataSources.length; i++) {
      final id = ids != null ? ids[i] : _generateUniqueId();
      _entries.add(
        PlayerFeedEntry(
          id: id,
          dataSource: dataSources[i],
        ),
      );
    }

    final targetIndex = initialIndex.clamp(0, _entries.length - 1);
    _currentIndex = targetIndex;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(targetIndex);
    }

    _reindexPool();
    notifyListeners();
    await onIndexChanged(targetIndex);
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _emitActiveMetrics();
    unawaited(_metricsController.close());

    for (final entry in _entries) {
      entry.leaseNotifier.value?.release();
      entry.dispose();
    }
    _entries.clear();

    if (_ownsPool) {
      _pool.dispose();
    }
    if (_ownsPageController) {
      _pageController.dispose();
    }
    super.dispose();
  }
}
