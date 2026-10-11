import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Represents a single demo showcase item in the example app.
class ExampleItem {
  const ExampleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.identifier,
    required this.pageBuilder,
    this.badgeText,
    this.badgeColor,
    this.supportedPlatforms,
    this.supportsWeb = true,
  });

  final String title;
  final String description;
  final IconData icon;
  final String identifier;
  final WidgetBuilder pageBuilder;
  final String? badgeText;
  final Color? badgeColor;

  /// Specific native target platforms where this demo feature functions.
  /// If null, all native platforms are considered supported.
  final Set<TargetPlatform>? supportedPlatforms;

  /// Whether this demo feature is supported on Flutter Web.
  final bool supportsWeb;

  /// Checks if the demo feature is supported on the current running platform.
  bool get isSupportedOnCurrentPlatform {
    if (kIsWeb) {
      return supportsWeb;
    }
    if (supportedPlatforms == null) {
      return true;
    }
    return supportedPlatforms!.contains(defaultTargetPlatform);
  }
}
