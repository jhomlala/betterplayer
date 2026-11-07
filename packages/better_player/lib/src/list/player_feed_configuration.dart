import 'package:better_player/better_player.dart' show BetterPlayerFeed;
import 'package:better_player/src/configuration/player_data_source.dart';
import 'package:better_player/src/list/better_player_feed.dart'
    show BetterPlayerFeed;
import 'package:material_ui/material_ui.dart';

/// Configuration for [BetterPlayerFeed].
class PlayerFeedConfiguration {
  /// Creates a configuration for [BetterPlayerFeed].
  const PlayerFeedConfiguration({
    this.scrollDirection = Axis.vertical,
    this.placeholderBuilder,
    this.errorBuilder,
    this.autoPlay = true,
  });

  /// The axis along which the feed scrolls.
  final Axis scrollDirection;

  /// Builder for placeholder widgets while the video is buffering
  /// or before the first frame is rendered.
  final Widget Function(
    BuildContext context,
    int index,
    PlayerDataSource dataSource,
  )?
  placeholderBuilder;

  /// Builder for error fallback widgets if a video fails to play.
  final Widget Function(
    BuildContext context,
    int index,
    PlayerDataSource dataSource,
    String? errorMessage,
  )?
  errorBuilder;

  /// Whether the currently focused item should play automatically.
  final bool autoPlay;

  /// Creates a copy of this configuration with given fields replaced.
  PlayerFeedConfiguration copyWith({
    Axis? scrollDirection,
    Widget Function(
      BuildContext context,
      int index,
      PlayerDataSource dataSource,
    )?
    placeholderBuilder,
    Widget Function(
      BuildContext context,
      int index,
      PlayerDataSource dataSource,
      String? errorMessage,
    )?
    errorBuilder,
    bool? autoPlay,
  }) {
    return PlayerFeedConfiguration(
      scrollDirection: scrollDirection ?? this.scrollDirection,
      placeholderBuilder: placeholderBuilder ?? this.placeholderBuilder,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      autoPlay: autoPlay ?? this.autoPlay,
    );
  }
}
