import 'package:better_player/src/core/better_player_extension.dart';

/// Lets an extension control security and content protection features in Better Player.
///
/// Base implementations return default safe values.
/// Subclasses override only the capabilities they manage.
abstract class PlayerSecurityExtension extends BetterPlayerExtension {
  /// Creates a security extension.
  const PlayerSecurityExtension();

  /// Whether the host application is authorized to activate OS screen capture protection.
  ///
  /// Defaults to false.
  bool get isScreenCaptureProtectionAuthorized => false;
}
