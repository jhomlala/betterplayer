import 'package:better_player/src/configuration/player_data_source.dart';
import 'package:better_player/src/list/player_pool_lease.dart';
import 'package:material_ui/material_ui.dart';

/// Internal entry representation for an item in a feed.
class PlayerFeedEntry {
  /// Creates a new feed entry.
  PlayerFeedEntry({
    required this.id,
    required this.dataSource,
    ValueNotifier<PlayerPoolLease?>? leaseNotifier,
  }) : leaseNotifier = leaseNotifier ?? ValueNotifier<PlayerPoolLease?>(null);

  /// Stable unique identifier of the entry.
  final String id;

  /// Associated data source.
  PlayerDataSource dataSource;

  /// Notifier exposing the active pool lease for this entry.
  final ValueNotifier<PlayerPoolLease?> leaseNotifier;

  /// Disposes the lease notifier.
  void dispose() {
    leaseNotifier.dispose();
  }
}
