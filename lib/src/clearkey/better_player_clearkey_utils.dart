import 'dart:convert';

import 'dart:typed_data';

///ClearKey helper class to generate the key
class BetterPlayerClearKeyUtils {
  //The ClearKey from a Map. The key in map should be the kid with the associated value being the key. Both values should be provide in HEX format.
  static String generate(Map<String, String> keys,
      {String type = "temporary"}) {
    Map keyMap = <String, dynamic>{"type": type};
    keyMap["keys"] = <Map<String, String>>[];
    keys.forEach((key, value) => keyMap["keys"]
        .add({"kty": "oct", "kid": _base64(key), "k": _base64(value)}));

    print(jsonEncode(keyMap));
    return jsonEncode(keyMap);
  }

  static String _base64(String source) {
    return base64
        .encode(_encodeBigInt(BigInt.parse(source, radix: 16)))
        .replaceAll("=", "");
  }

  static final _byteMask = BigInt.from(0xff);

  static Uint8List _encodeBigInt(BigInt number, {int? outLen}) {
    int size = (number.bitLength + 7) >> 3;

    final result = Uint8List(size);
    int pos = size - 1;
    for (int i = 0; i < size; i++) {
      result[pos--] = (number & _byteMask).toInt();
      number = number >> 8;
    }
    return result;
  }
}
