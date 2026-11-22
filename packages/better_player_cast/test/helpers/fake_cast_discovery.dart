import 'dart:async';

import 'package:better_player_cast/better_player_cast.dart';

/// In-memory fake device discovery for testing Cast UI and extensions.
class FakeCastDiscovery implements CastDiscovery {
  final StreamController<List<CastDevice>> _controller =
      StreamController<List<CastDevice>>.broadcast();
  List<CastDevice> _devices = <CastDevice>[];
  bool _isScanning = false;

  @override
  Stream<List<CastDevice>> get devicesStream => _controller.stream;

  @override
  List<CastDevice> get devices => List<CastDevice>.unmodifiable(_devices);

  @override
  bool get isScanning => _isScanning;

  /// Simulates discovering a new set of devices.
  void emitDevices(List<CastDevice> newDevices) {
    _devices = List<CastDevice>.from(newDevices);
    _controller.add(_devices);
  }

  @override
  Future<void> start() async {
    _isScanning = true;
  }

  @override
  Future<void> stop() async {
    _isScanning = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
