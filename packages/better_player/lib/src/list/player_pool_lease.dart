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

  bool _isReleased = false;

  /// Whether this lease is currently valid and still assigned to the item.
  bool get isValid => !_isReleased;

  /// Releases this lease back to the pool.
  void release() {
    if (_isReleased) {
      return;
    }
    _isReleased = true;
    onRelease(this);
  }

  /// Internal mark when evicted directly by the pool.
  void markEvicted() {
    _isReleased = true;
  }
}
