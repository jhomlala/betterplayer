import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_cast/src/discovery/cast_discovery.dart';
import 'package:better_player_cast/src/models/cast_device.dart';
import 'package:bonsoir/bonsoir.dart';

/// [CastDiscovery] implementation using [BonsoirDiscovery] for native mDNS Zeroconf resolution.
class BonsoirCastDiscovery implements CastDiscovery {
  /// Cast mDNS service type URN.
  static const String castServiceType = '_googlecast._tcp';

  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;
  final Map<String, CastDevice> _deviceMap = {};
  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();
  bool _isScanning = false;

  @override
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;

  @override
  List<CastDevice> get devices => _deviceMap.values.toList();

  @override
  bool get isScanning => _isScanning;

  @override
  Future<void> start() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final discovery = BonsoirDiscovery(type: castServiceType);
      _discovery = discovery;
      await discovery.initialize();

      _subscription = discovery.eventStream?.listen(
        (event) => _handleDiscoveryEvent(event, discovery),
        onError: (Object error) {
          PlayerLogger.error(message: 'Cast mDNS discovery error: $error');
        },
      );

      await discovery.start();
    } on Object catch (error) {
      _isScanning = false;
      PlayerLogger.error(
        message: 'Failed to start Bonsoir Cast discovery: $error',
      );
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _isScanning = false;
    await _subscription?.cancel();
    _subscription = null;

    try {
      await _discovery?.stop();
    } on Object catch (error) {
      PlayerLogger.warning(
        message: 'Error stopping Bonsoir discovery: $error',
      );
    }
    _discovery = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _devicesController.close();
  }

  void _handleDiscoveryEvent(
    BonsoirDiscoveryEvent event,
    BonsoirDiscovery discovery,
  ) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      event.service.resolve(discovery.serviceResolver);
    } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
      _onServiceResolved(event.service);
    } else if (event is BonsoirDiscoveryServiceLostEvent) {
      _onServiceLost(event.service);
    }
  }

  void _onServiceResolved(BonsoirService service) {
    final host = _extractHost(service);
    if (host == null) return;

    final name = service.attributes['fn'] ?? service.name;
    final model = service.attributes['md'];
    final id = service.attributes['id'] ?? '${host}_${service.port}';

    final device = CastDevice(
      id: id,
      name: name,
      host: host,
      port: service.port > 0 ? service.port : 8009,
      modelName: model,
    );

    _deviceMap[device.id] = device;
    _devicesController.add(_deviceMap.values.toList());
  }

  void _onServiceLost(BonsoirService service) {
    final id = service.attributes['id'] ?? service.name;
    _deviceMap.remove(id);
    _deviceMap.removeWhere((_, d) => d.name == service.name);
    _devicesController.add(_deviceMap.values.toList());
  }

  String? _extractHost(BonsoirService service) {
    if (service.hostAddresses.isNotEmpty) {
      return service.hostAddresses.first;
    }
    return service.hostname;
  }
}
