import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Represents a raw CastV2 protocol message.
@immutable
class CastMessage {
  /// Creates a Cast message.
  const CastMessage({
    required this.sourceId,
    required this.destinationId,
    required this.namespace,
    this.protocolVersion = 0,
    this.payloadType = 0,
    this.payloadUtf8,
    this.payloadBinary,
  });

  /// Protocol version (0 = CASTV2_1_0).
  final int protocolVersion;

  /// Source endpoint identifier (e.g. "sender-0").
  final String sourceId;

  /// Destination endpoint identifier (e.g. "receiver-0" or transportId).
  final String destinationId;

  /// Cast namespace URN.
  final String namespace;

  /// Payload type: 0 for STRING, 1 for BINARY.
  final int payloadType;

  /// UTF-8 string payload (usually JSON).
  final String? payloadUtf8;

  /// Binary payload if payloadType is 1.
  final Uint8List? payloadBinary;

  @override
  String toString() =>
      'CastMessage(ns: $namespace, src: $sourceId, dst: $destinationId, payload: $payloadUtf8)';
}
