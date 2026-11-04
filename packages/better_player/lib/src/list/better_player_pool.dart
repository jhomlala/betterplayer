import 'dart:async';

import 'package:better_player/src/configuration/player_data_source.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/list/player_pool_configuration.dart';
import 'package:better_player/src/list/player_pool_lease.dart';
import 'package:better_player/src/list/player_preload_mode.dart';
import 'package:better_player/src/logging/player_logger.dart';

/// Entry representing a pooled controller and its allocation state.
class _PlayerPoolSlot {
  _PlayerPoolSlot({
    required this.controller,
  });

  final BetterPlayerController controller;
  String? currentItemId;
  int? currentIndex;
  String? currentSourceUrl;
  PlayerPoolLease? currentLease;
  Future<PlayerPoolLease>? bindingFuture;
  bool isPreloading = false;
  bool isBusy = false;

  bool get isFree => currentItemId == null && !isBusy;
}

/// Request waiting for a controller slot.
class _PlayerPoolRequest {
  _PlayerPoolRequest({
    required this.itemId,
    required this.index,
    required this.dataSource,
    required this.completer,
  });

  final String itemId;
  final int index;
  final PlayerDataSource dataSource;
  final Completer<PlayerPoolLease> completer;
}

/// Manages a bounded pool of [BetterPlayerController] instances for high-performance
/// feeds. Provides distance-based recycling, slot queueing, and lifecycle management.
class BetterPlayerPool {
  /// Creates a pool with the given [configuration].
  BetterPlayerPool({
    this.configuration = const PlayerPoolConfiguration(),
    List<BetterPlayerController>? existingControllers,
  }) {
    _initPool(existingControllers);
  }

  /// Configuration settings for this pool.
  final PlayerPoolConfiguration configuration;

  final List<_PlayerPoolSlot> _slots = [];
  final List<_PlayerPoolRequest> _pendingRequests = [];
  int _activeIndex = 0;
  bool _isDisposed = false;
  bool _isForeground = true;

  /// Number of total slots in this pool.
  int get poolSize => _slots.length;

  /// Number of currently leased slots.
  int get leasedCount => _slots.where((slot) => !slot.isFree).length;

  /// Currently focused feed index.
  int get activeIndex => _activeIndex;

  /// Whether the app is currently in the foreground.
  bool get isForeground => _isForeground;

  /// Whether this pool has been disposed.
  bool get isDisposed => _isDisposed;

  void _initPool(List<BetterPlayerController>? existingControllers) {
    final poolConfig = configuration.playerConfiguration.copyWith(
      autoDispose: false,
      handleLifecycle: false,
    );

    for (var i = 0; i < configuration.poolSize; i++) {
      final controller =
          existingControllers != null && i < existingControllers.length
          ? existingControllers[i]
          : BetterPlayerController(poolConfig);
      _slots.add(_PlayerPoolSlot(controller: controller));
    }
  }

  /// Updates the currently focused feed index. Drives distance-based eviction.
  void setActiveIndex(int index) {
    if (_isDisposed) {
      return;
    }
    _activeIndex = index;
  }

  /// Acquires a lease for an item with [itemId] at position [index], bound to [dataSource].
  ///
  /// If a controller is already bound to this [itemId], returns it immediately.
  /// If all slots are occupied, evicts the slot furthest from [_activeIndex].
  /// If an eviction is not yet ready, queues the request and completes as soon
  /// as a slot becomes available.
  Future<PlayerPoolLease> acquire({
    required String itemId,
    required int index,
    required PlayerDataSource dataSource,
  }) async {
    if (_isDisposed) {
      throw StateError('BetterPlayerPool has been disposed');
    }

    // 1. Check if item already holds an active or preloading slot.
    for (final slot in _slots) {
      if (slot.currentItemId == itemId &&
          slot.currentLease != null &&
          !slot.currentLease!.hasError) {
        slot.currentIndex = index;
        final wasPreload = slot.isPreloading;
        slot.isPreloading = false;
        final lease = slot.currentLease!;
        if (wasPreload) {
          lease.wasPreloaded = true;
        }
        if (slot.bindingFuture != null) {
          await slot.bindingFuture;
        }
        return lease;
      }
    }

    // 2. Check for a completely free slot.
    final freeSlot = _findFreeSlot();
    if (freeSlot != null) {
      return _bindSlot(
        slot: freeSlot,
        itemId: itemId,
        index: index,
        dataSource: dataSource,
      );
    }

    // 3. Evict non-busy slot furthest from active index.
    final evictionCandidate = _findFurthestSlot(targetIndex: index);
    if (evictionCandidate != null) {
      _evictSlot(evictionCandidate);
      return _bindSlot(
        slot: evictionCandidate,
        itemId: itemId,
        index: index,
        dataSource: dataSource,
      );
    }

    // 4. All slots are busy; queue request.
    final completer = Completer<PlayerPoolLease>();
    _pendingRequests.add(
      _PlayerPoolRequest(
        itemId: itemId,
        index: index,
        dataSource: dataSource,
        completer: completer,
      ),
    );
    return completer.future;
  }

  /// Releases a previously assigned lease back to the pool.
  void release(PlayerPoolLease lease) {
    if (_isDisposed) {
      return;
    }

    for (final slot in _slots) {
      if (slot.currentLease == lease) {
        _resetSlot(slot);
        _processPendingRequests();
        break;
      }
    }
  }

  /// Releases any lease or pending request associated with [itemId].
  void releaseItem({required String itemId}) {
    if (_isDisposed) {
      return;
    }

    _pendingRequests.removeWhere((req) {
      if (req.itemId == itemId) {
        if (!req.completer.isCompleted) {
          req.completer.completeError(
            StateError('Item $itemId was released before acquiring lease'),
          );
        }
        return true;
      }
      return false;
    });

    for (final slot in _slots) {
      if (slot.currentItemId == itemId) {
        final currentLease = slot.currentLease;
        if (currentLease != null) {
          currentLease.markEvicted();
        }
        _resetSlot(slot);
        _processPendingRequests();
        break;
      }
    }
  }

  /// Updates the pool index tracking for all occupied slots based on [indexById].
  void reindex({required Map<String, int> indexById}) {
    if (_isDisposed) {
      return;
    }

    for (final slot in _slots) {
      final itemId = slot.currentItemId;
      if (itemId != null && indexById.containsKey(itemId)) {
        slot.currentIndex = indexById[itemId];
      }
    }
  }

  /// Returns the controller assigned to [itemId], if any.
  BetterPlayerController? getController(String itemId) {
    for (final slot in _slots) {
      if (slot.currentItemId == itemId) {
        return slot.controller;
      }
    }
    return null;
  }

  /// Preloads lookahead/lookbehind items around [currentIndex].
  void updatePreloads({
    required int currentIndex,
    required List<PlayerDataSource> dataSources,
    required String Function(int index) idGetter,
  }) {
    if (_isDisposed) {
      return;
    }
    setActiveIndex(currentIndex);

    final forward = configuration.preloadForward;
    final backward = configuration.preloadBackward;

    for (var offset = 1; offset <= forward; offset++) {
      final target = currentIndex + offset;
      if (target < dataSources.length) {
        _preloadItem(
          index: target,
          itemId: idGetter(target),
          dataSource: dataSources[target],
        );
      }
    }

    for (var offset = 1; offset <= backward; offset++) {
      final target = currentIndex - offset;
      if (target >= 0) {
        _preloadItem(
          index: target,
          itemId: idGetter(target),
          dataSource: dataSources[target],
        );
      }
    }
  }

  void _preloadItem({
    required int index,
    required String itemId,
    required PlayerDataSource dataSource,
  }) {
    if (getController(itemId) != null) {
      return;
    }

    final freeSlot = _findFreeSlot();
    if (freeSlot == null) {
      return;
    }

    unawaited(
      _bindSlot(
        slot: freeSlot,
        itemId: itemId,
        index: index,
        dataSource: dataSource,
        isPreload: true,
      ),
    );
  }

  _PlayerPoolSlot? _findFreeSlot() {
    for (final slot in _slots) {
      if (slot.isFree) {
        return slot;
      }
    }
    return null;
  }

  _PlayerPoolSlot? _findFurthestSlot({required int targetIndex}) {
    _PlayerPoolSlot? candidate;
    var maxDistance = -1;

    for (final slot in _slots) {
      if (slot.isBusy) {
        continue;
      }
      final slotIndex = slot.currentIndex;
      if (slotIndex == null) {
        return slot;
      }

      final distance = (slotIndex - targetIndex).abs();
      if (candidate == null || distance > maxDistance) {
        maxDistance = distance;
        candidate = slot;
      }
    }
    return candidate;
  }

  void _evictSlot(_PlayerPoolSlot slot) {
    final oldLease = slot.currentLease;
    if (oldLease != null) {
      oldLease.markEvicted();
    }
    _resetSlot(slot);
  }

  void _resetSlot(_PlayerPoolSlot slot) {
    if (slot.currentSourceUrl != null) {
      try {
        if (slot.controller.videoPlayerValue?.initialized ?? false) {
          unawaited(slot.controller.pause().catchError((_) {}));
          unawaited(slot.controller.setVolume(1).catchError((_) {}));
        }
      } on Object catch (e) {
        PlayerLogger.warning(message: 'Error resetting pooled controller: $e');
      }
    }

    slot.currentItemId = null;
    slot.currentIndex = null;
    slot.currentSourceUrl = null;
    slot.currentLease = null;
    slot.bindingFuture = null;
    slot.isPreloading = false;
    slot.isBusy = false;
  }

  Future<PlayerPoolLease> _bindSlot({
    required _PlayerPoolSlot slot,
    required String itemId,
    required int index,
    required PlayerDataSource dataSource,
    bool isPreload = false,
  }) {
    final future = _performBindSlot(
      slot: slot,
      itemId: itemId,
      index: index,
      dataSource: dataSource,
      isPreload: isPreload,
    );
    slot.bindingFuture = future;
    return future;
  }

  Future<PlayerPoolLease> _performBindSlot({
    required _PlayerPoolSlot slot,
    required String itemId,
    required int index,
    required PlayerDataSource dataSource,
    required bool isPreload,
  }) async {
    slot.isBusy = true;
    slot.isPreloading = isPreload;
    slot.currentItemId = itemId;
    slot.currentIndex = index;

    final lease = PlayerPoolLease(
      itemId: itemId,
      controller: slot.controller,
      index: index,
      onRelease: release,
    );
    slot.currentLease = lease;

    try {
      // Setup data source if different from current URL
      if (slot.currentSourceUrl != dataSource.url) {
        try {
          await slot.controller.setupDataSource(dataSource);
          if (slot.currentLease != lease) {
            return lease;
          }
          if (slot.controller.videoPlayerValue?.hasError ?? false) {
            final error =
                slot.controller.videoPlayerValue?.errorDescription ??
                'Data source setup failed';
            slot.currentSourceUrl = null;
            lease.errorMessage = error;
            PlayerLogger.error(
              message: 'Error setting up data source in pool: $error',
            );
            if (isPreload) {
              _resetSlot(slot);
            }
            return lease;
          }
          slot.currentSourceUrl = dataSource.url;
        } on Object catch (e) {
          slot.currentSourceUrl = null;
          lease.errorMessage = e.toString();
          PlayerLogger.error(
            message: 'Error setting up data source in pool: $e',
          );
          if (isPreload) {
            _resetSlot(slot);
          }
          return lease;
        }
      }

      if (slot.isPreloading && slot.currentLease == lease) {
        if (configuration.preloadMode == PlayerPreloadMode.muted) {
          await slot.controller.setVolume(0);
          await slot.controller.play();
        } else {
          if (slot.controller.videoPlayerValue?.initialized ?? false) {
            await slot.controller.pause();
          }
        }
      }

      return lease;
    } finally {
      if (slot.currentLease == lease) {
        slot.isBusy = false;
        slot.bindingFuture = null;
      }
      if (!_isDisposed) {
        _processPendingRequests();
      }
    }
  }

  void _processPendingRequests() {
    if (_isDisposed || _pendingRequests.isEmpty) {
      return;
    }

    final freeSlot = _findFreeSlot();
    if (freeSlot != null) {
      final nextRequest = _pendingRequests.removeAt(0);
      _bindSlot(
            slot: freeSlot,
            itemId: nextRequest.itemId,
            index: nextRequest.index,
            dataSource: nextRequest.dataSource,
          )
          .then(nextRequest.completer.complete)
          .catchError(
            nextRequest.completer.completeError,
          );
      return;
    }

    final nextRequest = _pendingRequests.first;
    final evictionCandidate = _findFurthestSlot(
      targetIndex: nextRequest.index,
    );
    if (evictionCandidate != null) {
      _pendingRequests.removeAt(0);
      _evictSlot(evictionCandidate);
      _bindSlot(
            slot: evictionCandidate,
            itemId: nextRequest.itemId,
            index: nextRequest.index,
            dataSource: nextRequest.dataSource,
          )
          .then(nextRequest.completer.complete)
          .catchError(
            nextRequest.completer.completeError,
          );
    }
  }

  /// Invoked when the application moves into the background.
  void onAppBackground() {
    _isForeground = false;
    for (final slot in _slots) {
      if (slot.currentSourceUrl != null) {
        try {
          if (slot.controller.videoPlayerValue?.initialized ?? false) {
            unawaited(slot.controller.pause().catchError((_) {}));
          }
        } on Object catch (_) {}
      }
    }
  }

  /// Invoked when the application returns to the foreground.
  void onAppForeground() {
    _isForeground = true;
  }

  /// Disposes all controllers in this pool.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    for (final request in _pendingRequests) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
          StateError('BetterPlayerPool was disposed before resolving request'),
        );
      }
    }
    _pendingRequests.clear();

    for (final slot in _slots) {
      try {
        slot.controller.dispose(forceDispose: true);
      } on Object catch (_) {}
    }
    _slots.clear();
  }
}
