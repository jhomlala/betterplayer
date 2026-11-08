import 'dart:convert';
import 'dart:typed_data';

/// ClearKey helper class to generate the key payload.
class BetterPlayerClearKeyUtils {
  /// Generates the ClearKey JSON from a Map of key IDs to keys in HEX format.
  static String generateKey(
    Map<String, String> keys, {
    String type = 'temporary',
  }) {
    final keyList = <Map<String, String>>[];
    for (final entry in keys.entries) {
      keyList.add({
        'kty': 'oct',
        'kid': _base64(entry.key),
        'k': _base64(entry.value),
      });
    }

    final keyMap = <String, dynamic>{
      'type': type,
      'keys': keyList,
    };

    return jsonEncode(keyMap);
  }

  static String _base64(String source) {
    final clean = source.replaceAll(' ', '');
    final length = clean.length;
    final bytes = Uint8List(length ~/ 2);
    for (var i = 0; i < length; i += 2) {
      bytes[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
    }
    return base64.encode(bytes).replaceAll('=', '');
  }
}
