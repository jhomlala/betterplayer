import 'package:better_player/src/core/better_player_controller.dart';

/// A lease representing a temporarily bound [BetterPlayerController]
/// allocated from a [BetterPlayerPool].
class PlayerPoolLease {
  /// Creates a lease instance.
  PlayerPoolLease({
    required this.itemId,
    required this.controller,
    required this.index,
    required this.onRelease,
  });

  /// Identifier of the feed item that owns this lease.
  final String itemId;

  /// The allocated player controller.
  final BetterPlayerController controller;

  /// Position index of the item within the feed.
  final int index;

  /// Callback executed when this lease is released.
  final void Function(PlayerPoolLease lease) onRelease;

  final List<void Function()> _evictionListeners = [];

  bool _isReleased = false;

  /// Whether this lease is currently valid and still assigned to the item.
  bool get isValid => !_isReleased;

  /// Registers a callback invoked when this lease is evicted by the pool.
  void addEvictionListener(void Function() listener) {
    if (_isReleased) {
      return;
    }
    _evictionListeners.add(listener);
  }

  /// Removes a previously registered eviction callback.
  void removeEvictionListener(void Function() listener) {
    _evictionListeners.remove(listener);
  }

  /// Releases this lease back to the pool.
  void release() {
    if (_isReleased) {
      return;
    }
    _isReleased = true;
    _evictionListeners.clear();
    onRelease(this);
  }

  /// Internal mark when evicted directly by the pool.
  void markEvicted() {
    if (_isReleased) {
      return;
    }
    _isReleased = true;
    final listeners = List<void Function()>.of(_evictionListeners);
    _evictionListeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }
}
