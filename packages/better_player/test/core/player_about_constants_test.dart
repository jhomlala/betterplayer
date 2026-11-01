import 'dart:io';

import 'package:better_player/src/core/player_about_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerAboutConstants', () {
    test('version matches pubspec.yaml', () {
      final candidates = [
        File('packages/better_player/pubspec.yaml'),
        File('pubspec.yaml'),
      ];
      final file = candidates.firstWhere(
        (f) =>
            f.existsSync() &&
            RegExp(
              '^version:',
              multiLine: true,
            ).hasMatch(f.readAsStringSync()),
      );
      final pubspec = file.readAsStringSync();
      final match = RegExp(
        r'^version:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec);
      expect(match, isNotNull);
      expect(PlayerAboutConstants.version, match!.group(1));
    });

    test('urls use https', () {
      expect(PlayerAboutConstants.websiteUrl, startsWith('https://'));
      expect(PlayerAboutConstants.githubUrl, startsWith('https://'));
      expect(PlayerAboutConstants.issuesUrl, startsWith('https://'));
      expect(PlayerAboutConstants.logoUrl, startsWith('https://'));
    });
  });
}
