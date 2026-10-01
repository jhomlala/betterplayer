import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  final rootDir = Directory.current.path;
  final iosSourcesDir = p.join(
    rootDir,
    'packages',
    'better_player_ios',
    'ios',
    'better_player_ios',
    'Sources',
    'better_player_ios',
  );

  final macosSourcesDir = p.join(
    rootDir,
    'packages',
    'better_player_macos',
    'macos',
    'better_player_macos',
    'Sources',
    'better_player_macos',
  );

  final sharedFiles = [
    'BetterPlayerApi.swift',
    'BetterPlayerEzDrmAssetsLoaderDelegate.swift',
    'BetterPlayerTimeUtils.swift',
    'CacheManager.swift',
    'CachingPlayerItem.swift',
    'PrivacyInfo.xcprivacy',
  ];

  final targetDir = Directory(macosSourcesDir);
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  for (final filename in sharedFiles) {
    final sourceFile = File(p.join(iosSourcesDir, filename));
    if (!sourceFile.existsSync()) {
      stderr.writeln('Warning: Source file not found: ${sourceFile.path}');
      continue;
    }
    final destFile = File(p.join(macosSourcesDir, filename));
    sourceFile.copySync(destFile.path);
    stdout.writeln('Synced: $filename -> ${destFile.path}');
  }

  stdout.writeln('Apple core sync completed successfully.');
}
