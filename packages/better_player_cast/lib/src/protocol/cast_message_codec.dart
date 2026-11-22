import 'dart:convert';
import 'dart:typed_data';

import 'package:better_player_cast/src/protocol/cast_message.dart';

/// Internal reference to track read position in byte buffers.
class _OffsetRef {
  _OffsetRef(this.offset);
  int offset;
}

/// Binary encoder and decoder for CastV2 wire frames.
class CastMessageCodec {
  /// Maximum permitted payload frame size (1 MB guard).
  static const int maxFrameSize = 1024 * 1024;

  /// Encodes a [CastMessage] into a 4-byte length-prefixed frame.
  Uint8List encodeMessage(CastMessage message) {
    final payloadBytes = <int>[];

    // Field 1: protocolVersion (varint, tag 8)
    _writeVarint(payloadBytes, (1 << 3) | 0);
    _writeVarint(payloadBytes, message.protocolVersion);

    // Field 2: sourceId (length-delimited, tag 18)
    _writeString(payloadBytes, fieldNumber: 2, value: message.sourceId);

    // Field 3: destinationId (length-delimited, tag 26)
    _writeString(payloadBytes, fieldNumber: 3, value: message.destinationId);

    // Field 4: namespace (length-delimited, tag 34)
    _writeString(payloadBytes, fieldNumber: 4, value: message.namespace);

    // Field 5: payloadType (varint, tag 40)
    _writeVarint(payloadBytes, (5 << 3) | 0);
    _writeVarint(payloadBytes, message.payloadType);

    // Field 6: payloadUtf8 (length-delimited, tag 50)
    if (message.payloadUtf8 != null) {
      _writeString(payloadBytes, fieldNumber: 6, value: message.payloadUtf8!);
    }

    // Field 7: payloadBinary (length-delimited, tag 58)
    if (message.payloadBinary != null) {
      _writeBytes(payloadBytes, fieldNumber: 7, bytes: message.payloadBinary!);
    }

    final frameLen = payloadBytes.length;
    final frame = Uint8List(4 + frameLen);
    frame[0] = (frameLen >> 24) & 0xFF;
    frame[1] = (frameLen >> 16) & 0xFF;
    frame[2] = (frameLen >> 8) & 0xFF;
    frame[3] = frameLen & 0xFF;
    frame.setRange(4, 4 + frameLen, payloadBytes);
    return frame;
  }

  /// Appends incoming [chunk] to [buffer] and extracts all complete [CastMessage]s.
  List<CastMessage> decodeMessages({
    required Uint8List chunk,
    required List<int> buffer,
  }) {
    buffer.addAll(chunk);
    final messages = <CastMessage>[];

    while (buffer.length >= 4) {
      final frameLen =
          (buffer[0] << 24) | (buffer[1] << 16) | (buffer[2] << 8) | buffer[3];

      if (frameLen < 0 || frameLen > maxFrameSize) {
        buffer.clear();
        throw FormatException('Cast frame size out of bounds: $frameLen');
      }

      if (buffer.length < 4 + frameLen) {
        break; // Incomplete frame, wait for more data.
      }

      final payloadBytes = Uint8List.fromList(
        buffer.sublist(4, 4 + frameLen),
      );
      buffer.removeRange(0, 4 + frameLen);

      messages.add(decodeSinglePayload(payloadBytes));
    }

    return messages;
  }

  /// Decodes raw protobuf payload bytes into a [CastMessage].
  CastMessage decodeSinglePayload(Uint8List data) {
    final ref = _OffsetRef(0);
    var protocolVersion = 0;
    var sourceId = '';
    var destinationId = '';
    var namespace = '';
    var payloadType = 0;
    String? payloadUtf8;
    Uint8List? payloadBinary;

    while (ref.offset < data.length) {
      final key = _readVarint(data, ref);
      final fieldNumber = key >> 3;
      final wireType = key & 0x07;

      switch (wireType) {
        case 0: // Varint
          final value = _readVarint(data, ref);
          if (fieldNumber == 1) protocolVersion = value;
          if (fieldNumber == 5) payloadType = value;
        case 2: // Length-delimited
          final len = _readVarint(data, ref);
          if (ref.offset + len > data.length) {
            throw const FormatException('Protobuf field length exceeds buffer');
          }
          final fieldBytes = data.sublist(ref.offset, ref.offset + len);
          ref.offset += len;

          if (fieldNumber == 2) sourceId = utf8.decode(fieldBytes);
          if (fieldNumber == 3) destinationId = utf8.decode(fieldBytes);
          if (fieldNumber == 4) namespace = utf8.decode(fieldBytes);
          if (fieldNumber == 6) payloadUtf8 = utf8.decode(fieldBytes);
          if (fieldNumber == 7) payloadBinary = fieldBytes;
        default:
          _skipField(data, ref, wireType);
      }
    }

    return CastMessage(
      protocolVersion: protocolVersion,
      sourceId: sourceId,
      destinationId: destinationId,
      namespace: namespace,
      payloadType: payloadType,
      payloadUtf8: payloadUtf8,
      payloadBinary: payloadBinary,
    );
  }

  static void _writeVarint(List<int> out, int value) {
    var v = value;
    while (v >= 0x80) {
      out.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    out.add(v & 0x7F);
  }

  static void _writeString(
    List<int> out, {
    required int fieldNumber,
    required String value,
  }) {
    final bytes = utf8.encode(value);
    _writeBytes(out, fieldNumber: fieldNumber, bytes: bytes);
  }

  static void _writeBytes(
    List<int> out, {
    required int fieldNumber,
    required List<int> bytes,
  }) {
    _writeVarint(out, (fieldNumber << 3) | 2);
    _writeVarint(out, bytes.length);
    out.addAll(bytes);
  }

  static int _readVarint(Uint8List data, _OffsetRef ref) {
    var result = 0;
    var shift = 0;
    while (ref.offset < data.length) {
      final byte = data[ref.offset++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) return result;
      shift += 7;
      if (shift >= 64) throw const FormatException('Varint overflow');
    }
    throw const FormatException('Unexpected end of varint stream');
  }

  static void _skipField(Uint8List data, _OffsetRef ref, int wireType) {
    switch (wireType) {
      case 1: // 64-bit
        ref.offset += 8;
      case 5: // 32-bit
        ref.offset += 4;
      default:
        throw FormatException('Unsupported wire type: $wireType');
    }
  }
}
