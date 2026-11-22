import 'dart:async';
import 'package:better_player_cast/better_player_cast.dart';

/// Predictable fake device discovery for Maestro Cast E2E flows.
class E2EFakeCastDiscovery implements CastDiscovery {
  /// Creates an E2E fake discovery instance.
  E2EFakeCastDiscovery({
    required this.device,
  });

  /// The device that will be exposed.
  final CastDevice device;

  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();

  bool _isScanning = false;

  @override
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;

  @override
  List<CastDevice> get devices => _isScanning ? [device] : const [];

  @override
  bool get isScanning => _isScanning;

  @override
  Future<void> start() async {
    _isScanning = true;
    _devicesController.add([device]);
  }

  @override
  Future<void> stop() async {
    _isScanning = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _devicesController.close();
  }
}
