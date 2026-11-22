import 'dart:typed_data';

import 'package:better_player_cast/better_player_cast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CastMessageCodec', () {
    late CastMessageCodec codec;

    setUp(() {
      codec = CastMessageCodec();
    });

    test('encodes and decodes string payload message round-trip', () {
      const message = CastMessage(
        sourceId: 'sender-0',
        destinationId: 'receiver-0',
        namespace: CastNamespaces.heartbeat,
        payloadUtf8: '{"type":"PING"}',
      );

      final encoded = codec.encodeMessage(message);
      expect(encoded.length, greaterThan(4));

      final buffer = <int>[];
      final decoded = codec.decodeMessages(chunk: encoded, buffer: buffer);

      expect(decoded.length, equals(1));
      expect(decoded.first.sourceId, equals('sender-0'));
      expect(decoded.first.destinationId, equals('receiver-0'));
      expect(decoded.first.namespace, equals(CastNamespaces.heartbeat));
      expect(decoded.first.payloadType, equals(0));
      expect(decoded.first.payloadUtf8, equals('{"type":"PING"}'));
      expect(decoded.first.payloadBinary, isNull);
      expect(buffer, isEmpty);
    });

    test('encodes and decodes binary payload message round-trip', () {
      final binaryData = Uint8List.fromList([1, 2, 3, 4, 5, 255]);
      final message = CastMessage(
        sourceId: 'sender-0',
        destinationId: 'transport-1',
        namespace: 'urn:x-cast:com.google.cast.test',
        payloadType: 1,
        payloadBinary: binaryData,
      );

      final encoded = codec.encodeMessage(message);
      final buffer = <int>[];
      final decoded = codec.decodeMessages(chunk: encoded, buffer: buffer);

      expect(decoded.length, equals(1));
      expect(decoded.first.payloadType, equals(1));
      expect(decoded.first.payloadBinary, equals(binaryData));
      expect(decoded.first.payloadUtf8, isNull);
    });

    test('handles split chunk streams across multiple arrivals', () {
      const message = CastMessage(
        sourceId: 'sender-0',
        destinationId: 'receiver-0',
        namespace: CastNamespaces.receiver,
        payloadUtf8: '{"type":"GET_STATUS","requestId":1}',
      );

      final encoded = codec.encodeMessage(message);
      final mid = encoded.length ~/ 2;
      final part1 = encoded.sublist(0, mid);
      final part2 = encoded.sublist(mid);

      final buffer = <int>[];

      // First part should not emit a complete message
      final firstPass = codec.decodeMessages(chunk: part1, buffer: buffer);
      expect(firstPass, isEmpty);
      expect(buffer, isNotEmpty);

      // Second part completes the frame
      final secondPass = codec.decodeMessages(chunk: part2, buffer: buffer);
      expect(secondPass.length, equals(1));
      expect(secondPass.first.namespace, equals(CastNamespaces.receiver));
      expect(secondPass.first.payloadUtf8, contains('GET_STATUS'));
      expect(buffer, isEmpty);
    });

    test('handles multiple coalesced messages in a single chunk', () {
      const msg1 = CastMessage(
        sourceId: 'sender-0',
        destinationId: 'receiver-0',
        namespace: CastNamespaces.heartbeat,
        payloadUtf8: '{"type":"PING"}',
      );
      const msg2 = CastMessage(
        sourceId: 'sender-0',
        destinationId: 'receiver-0',
        namespace: CastNamespaces.heartbeat,
        payloadUtf8: '{"type":"PONG"}',
      );

      final encoded1 = codec.encodeMessage(msg1);
      final encoded2 = codec.encodeMessage(msg2);
      final combined = Uint8List.fromList([...encoded1, ...encoded2]);

      final buffer = <int>[];
      final messages = codec.decodeMessages(chunk: combined, buffer: buffer);

      expect(messages.length, equals(2));
      expect(messages[0].payloadUtf8, equals('{"type":"PING"}'));
      expect(messages[1].payloadUtf8, equals('{"type":"PONG"}'));
      expect(buffer, isEmpty);
    });

    test('throws FormatException on oversized frame and clears buffer', () {
      // 4-byte length representing 2MB (exceeds 1MB limit)
      final badHeader = Uint8List.fromList([
        0x00,
        0x20,
        0x00,
        0x00,
        0x01,
        0x02,
      ]);
      final buffer = <int>[];

      expect(
        () => codec.decodeMessages(chunk: badHeader, buffer: buffer),
        throwsA(isA<FormatException>()),
      );
      expect(buffer, isEmpty);
    });

    test('decodeSinglePayload directly unpacks serialized protobuf', () {
      const message = CastMessage(
        sourceId: 'src',
        destinationId: 'dst',
        namespace: 'ns',
        payloadUtf8: 'test',
      );
      final fullFrame = codec.encodeMessage(message);
      final payloadBytes = fullFrame.sublist(4);

      final decoded = codec.decodeSinglePayload(payloadBytes);
      expect(decoded.sourceId, equals('src'));
      expect(decoded.destinationId, equals('dst'));
      expect(decoded.namespace, equals('ns'));
      expect(decoded.payloadUtf8, equals('test'));
    });
  });
}
