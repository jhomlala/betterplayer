import 'package:better_player_cast/src/models/cast_device.dart';

/// Contract for discovering Cast-capable devices on the local network.
abstract class CastDiscovery {
  /// Stream of discovered Cast devices on the network.
  Stream<List<CastDevice>> get devicesStream;

  /// Current snapshot list of discovered Cast devices.
  List<CastDevice> get devices;

  /// Whether discovery is currently actively scanning.
  bool get isScanning;

  /// Starts scanning for devices.
  Future<void> start();

  /// Stops scanning for devices.
  Future<void> stop();

  /// Disposes discovery resources and cancels streams.
  Future<void> dispose();
}
