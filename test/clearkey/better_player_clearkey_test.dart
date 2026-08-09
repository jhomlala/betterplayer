import 'dart:convert';
import 'package:better_player/src/clearkey/better_player_clearkey_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerClearKeyUtils tests', () {
    test('generateKey generates correct JSON', () {
      final keys = {
        '86aa0fde062e557b9893d56784d1664d': '397669d0234a90098f9a2e6399a9a3b6',
      };
      final jsonKey = BetterPlayerClearKeyUtils.generateKey(keys);
      final decoded = jsonDecode(jsonKey);

      expect(decoded['type'], 'temporary');
      expect(decoded['keys'].length, 1);
      expect(decoded['keys'][0]['kty'], 'oct');
      expect(decoded['keys'][0]['kid'], 'hqoP3gYuVXuYk9VnhNFmTQ');
      expect(decoded['keys'][0]['k'], 'OXZp0CNKkAmPmi5jmamjtg');
    });

    test('generateKey with multiple keys', () {
      // hex values are expected
      final hexKeys = {
        '0123456789abcdef': 'fedcba9876543210',
        'aabbccddeeff0011': '1100ffee99887766',
      };
      final jsonKey = BetterPlayerClearKeyUtils.generateKey(hexKeys);
      final decoded = jsonDecode(jsonKey);

      expect(decoded['keys'].length, 2);
    });
  });
}
