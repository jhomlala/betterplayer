import 'package:better_player/src/configuration/player_configuration.dart';

/// Preload strategy used by [BetterPlayerPool].
enum PlayerPreloadMode {
  /// Prepares the media source and pauses immediately once initialized.
  /// Minimum CPU and battery consumption.
  prepared,

  /// Prepares and plays the media at volume 0.0 to keep native codec
  /// and network buffers hot.
  muted,
}

/// Configuration for [BetterPlayerPool].
class PlayerPoolConfiguration {
  /// Creates a configuration for [BetterPlayerPool].
  const PlayerPoolConfiguration({
    this.poolSize = 3,
    this.preloadMode = PlayerPreloadMode.prepared,
    this.preloadForward = 1,
    this.preloadBackward = 1,
    this.playerConfiguration = const PlayerConfiguration(
      autoDispose: false,
      handleLifecycle: false,
    ),
  }) : assert(poolSize >= 2, 'poolSize must be at least 2'),
       assert(preloadForward >= 0, 'preloadForward must be non-negative'),
       assert(preloadBackward >= 0, 'preloadBackward must be non-negative');

  /// Maximum number of [BetterPlayerController] instances maintained by the pool.
  final int poolSize;

  /// Strategy used to preload lookahead/lookbehind media items.
  final PlayerPreloadMode preloadMode;

  /// Number of items ahead of the active index to keep preloaded.
  final int preloadForward;

  /// Number of items behind the active index to keep preloaded.
  final int preloadBackward;

  /// Base player configuration applied to all controllers in the pool.
  /// [PlayerConfiguration.autoDispose] and [PlayerConfiguration.handleLifecycle]
  /// are overridden to false by the pool to prevent premature disposal.
  final PlayerConfiguration playerConfiguration;

  /// Creates a copy of this configuration with given fields replaced.
  PlayerPoolConfiguration copyWith({
    int? poolSize,
    PlayerPreloadMode? preloadMode,
    int? preloadForward,
    int? preloadBackward,
    PlayerConfiguration? playerConfiguration,
  }) {
    return PlayerPoolConfiguration(
      poolSize: poolSize ?? this.poolSize,
      preloadMode: preloadMode ?? this.preloadMode,
      preloadForward: preloadForward ?? this.preloadForward,
      preloadBackward: preloadBackward ?? this.preloadBackward,
      playerConfiguration: playerConfiguration ?? this.playerConfiguration,
    );
  }
}
