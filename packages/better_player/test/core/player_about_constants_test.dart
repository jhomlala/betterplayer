import 'dart:io';

import 'package:better_player/src/core/player_about_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerAboutConstants', () {
    test('version matches pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
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
