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
      final decoded = jsonDecode(jsonKey) as Map<String, dynamic>;
      final keysList = (decoded['keys'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(decoded['type'], 'temporary');
      expect(keysList.length, 1);
      expect(keysList[0]['kty'], 'oct');
      expect(keysList[0]['kid'], 'hqoP3gYuVXuYk9VnhNFmTQ');
      expect(keysList[0]['k'], 'OXZp0CNKkAmPmi5jmamjtg');
    });

    test('generateKey with multiple keys', () {
      // hex values are expected
      final hexKeys = {
        '0123456789abcdef': 'fedcba9876543210',
        'aabbccddeeff0011': '1100ffee99887766',
      };
      final jsonKey = BetterPlayerClearKeyUtils.generateKey(hexKeys);
      final decoded = jsonDecode(jsonKey) as Map<String, dynamic>;
      final keysList = decoded['keys'] as List<dynamic>;

      expect(keysList.length, 2);
    });

    test('generateKey preserves leading zero bytes in 16-byte keys', () {
      final keys = {
        '00112233445566778899aabbccddeeff': '00000000000000000000000000000001',
      };
      final jsonKey = BetterPlayerClearKeyUtils.generateKey(keys);
      final decoded = jsonDecode(jsonKey) as Map<String, dynamic>;
      final keysList = (decoded['keys'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final kidBytes = base64.decode(
        base64.normalize(keysList[0]['kid'] as String),
      );
      final kBytes = base64.decode(
        base64.normalize(keysList[0]['k'] as String),
      );

      expect(kidBytes.length, 16);
      expect(kidBytes[0], 0x00);
      expect(kidBytes[1], 0x11);

      expect(kBytes.length, 16);
      expect(kBytes[0], 0x00);
      expect(kBytes[15], 0x01);
    });
  });
}
