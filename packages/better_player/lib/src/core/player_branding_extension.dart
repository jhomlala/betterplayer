import 'package:better_player/src/core/better_player_extension.dart';

/// Lets an extension change branding options of the player.
///
/// Every getter returns the default value, which means "no change".
/// Subclasses override only the options they control.
abstract class PlayerBrandingExtension extends BetterPlayerExtension {
  const PlayerBrandingExtension();

  /// Returns true to hide the About item in the overflow menu.
  bool get hideAboutMenu => false;
}
