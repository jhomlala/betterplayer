import 'package:meta/meta.dart';

/// Represents a discovered Chromecast or Google TV device on the local network.
@immutable
class CastDevice {
  /// Creates a Cast device description.
  const CastDevice({
    required this.id,
    required this.name,
    required this.host,
    this.port = 8009,
    this.modelName,
  });

  /// Unique identifier of the device (typically from mDNS id attribute or UUID).
  final String id;

  /// Human-readable friendly name of the device (e.g. "Living Room TV").
  final String name;

  /// IP address or hostname of the device.
  final String host;

  /// Port on which CastV2 TLS server listens (default: 8009).
  final int port;

  /// Model name of the device (e.g. "Chromecast", "Google TV").
  final String? modelName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CastDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => Object.hash(id, host, port);

  @override
  String toString() =>
      'CastDevice(id: $id, name: $name, host: $host, port: $port, model: $modelName)';
}
