import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_player_cast/src/config/cast_configuration.dart';
import 'package:better_player_cast/src/models/cast_device.dart';
import 'package:better_player_cast/src/models/cast_media_info.dart';
import 'package:better_player_cast/src/models/cast_media_status.dart';
import 'package:better_player_cast/src/models/cast_session_state.dart';
import 'package:better_player_cast/src/protocol/cast_message.dart';
import 'package:better_player_cast/src/protocol/cast_namespaces.dart';
import 'package:better_player_cast/src/protocol/cast_socket.dart';
import 'package:better_player_cast/src/protocol/cast_tls_socket.dart';

/// Manages a single active CastV2 connection, heartbeat, and media lifecycle.
class CastSession {
  /// Creates a Cast session with the provided configuration and socket factory.
  CastSession({
    this.configuration = const CastConfiguration(),
    CastSocketFactory? socketFactory,
  }) : _socketFactory = socketFactory ?? CastTlsSocket.connect;

  final CastConfiguration configuration;
  final CastSocketFactory _socketFactory;

  CastSocket? _socket;
  StreamSubscription<CastMessage>? _socketSubscription;
  Timer? _heartbeatTimer;
  DateTime _lastPongTime = DateTime.now();

  int _requestId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};

  CastDevice? _device;
  String? _sessionId;
  String? _transportId;
  int? _mediaSessionId;
  CastMediaStatus? _lastMediaStatus;

  final StreamController<CastSessionState> _stateController =
      StreamController<CastSessionState>.broadcast();
  final StreamController<CastMediaStatus> _mediaStatusController =
      StreamController<CastMediaStatus>.broadcast();

  CastSessionState _state = CastSessionState.disconnected;

  /// Current connection state of the session.
  CastSessionState get state => _state;

  /// Stream of connection state changes.
  Stream<CastSessionState> get stateStream => _stateController.stream;

  /// Currently connected device, if any.
  CastDevice? get device => _device;

  /// Latest media status reported by the receiver.
  CastMediaStatus? get mediaStatus => _lastMediaStatus;

  /// Stream of media status updates from the receiver.
  Stream<CastMediaStatus> get mediaStatusStream =>
      _mediaStatusController.stream;

  /// Whether the session is currently connected and ready.
  bool get isConnected => _state == CastSessionState.connected;

  /// Connects to the target [device] and establishes a CastV2 session.
  Future<void> connect(CastDevice device) async {
    _setState(CastSessionState.connecting);
    _device = device;

    try {
      _socket = await _socketFactory(
        host: device.host,
        port: device.port,
        timeout: configuration.connectTimeout,
      );

      _socketSubscription = _socket!.messages.listen(
        _onMessageReceived,
        onError: _onSocketError,
        onDone: _onSocketDone,
      );

      _connectTransport(CastNamespaces.defaultReceiverId);
      _startHeartbeat();

      await _launchOrJoinApp();
      _setState(CastSessionState.connected);
    } on Object catch (_) {
      await disconnect();
      rethrow;
    }
  }

  /// Loads media onto the receiver at the specified [startPosition].
  Future<CastMediaStatus?> loadMedia(
    CastMediaInfo mediaInfo, {
    Duration startPosition = Duration.zero,
    bool autoPlay = true,
  }) async {
    final transportId = _transportId;
    if (transportId == null) {
      throw StateError('Cannot load media: no active transport');
    }

    final reqId = _nextRequestId();
    final payload = <String, dynamic>{
      'type': 'LOAD',
      'requestId': reqId,
      'autoplay': autoPlay,
      'currentTime': startPosition.inMilliseconds / 1000.0,
      'media': mediaInfo.toJson(),
    };

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[reqId] = completer;

    _sendJson(
      namespace: CastNamespaces.media,
      destinationId: transportId,
      json: payload,
    );

    final res = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => <String, dynamic>{},
    );

    final statuses = res['status'] as List<dynamic>?;
    if (statuses != null && statuses.isNotEmpty) {
      final statusMap = statuses.first as Map<String, dynamic>;
      final status = CastMediaStatus.fromJson(statusMap);
      _mediaSessionId = status.mediaSessionId;
      _lastMediaStatus = status;
      return status;
    }
    return _lastMediaStatus;
  }

  /// Sends a PLAY command to the receiver.
  Future<void> play() async {
    await _sendMediaCommand(type: 'PLAY');
  }

  /// Sends a PAUSE command to the receiver.
  Future<void> pause() async {
    await _sendMediaCommand(type: 'PAUSE');
  }

  /// Sends a SEEK command to the receiver.
  Future<void> seek(Duration position) async {
    await _sendMediaCommand(
      type: 'SEEK',
      extra: {'currentTime': position.inMilliseconds / 1000.0},
    );
  }

  /// Sets the receiver volume level (0.0 to 1.0).
  Future<void> setVolume(double level, {bool? muted}) async {
    final reqId = _nextRequestId();
    final volume = <String, dynamic>{'level': level.clamp(0.0, 1.0)};
    if (muted != null) volume['muted'] = muted;

    _sendJson(
      namespace: CastNamespaces.receiver,
      destinationId: CastNamespaces.defaultReceiverId,
      json: {
        'type': 'SET_VOLUME',
        'requestId': reqId,
        'volume': volume,
      },
    );
  }

  /// Stops playback and closes the receiver application.
  Future<void> stop() async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      final reqId = _nextRequestId();
      _sendJson(
        namespace: CastNamespaces.receiver,
        destinationId: CastNamespaces.defaultReceiverId,
        json: {
          'type': 'STOP',
          'requestId': reqId,
          'sessionId': sessionId,
        },
      );
    }
  }

  /// Disconnects from the receiver and frees all socket resources.
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    final transportId = _transportId;
    if (transportId != null && _socket != null) {
      _sendJson(
        namespace: CastNamespaces.connection,
        destinationId: transportId,
        json: {'type': 'CLOSE'},
      );
    }

    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(const SocketException('Cast disconnected'));
      }
    }
    _pendingRequests.clear();

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    await _socket?.close();
    _socket = null;

    _transportId = null;
    _sessionId = null;
    _mediaSessionId = null;
    _lastMediaStatus = null;
    _device = null;

    _setState(CastSessionState.disconnected);
  }

  Future<void> _launchOrJoinApp() async {
    final status = await _getReceiverStatus();
    final apps = status['applications'] as List<dynamic>?;
    if (apps != null) {
      for (final app in apps) {
        if (app is Map<String, dynamic> &&
            app['appId'] == configuration.receiverAppId) {
          _sessionId = app['sessionId'] as String?;
          _transportId = app['transportId'] as String?;
          if (_transportId != null) {
            _connectTransport(_transportId!);
            return;
          }
        }
      }
    }

    final launchRes = await _launchApp(configuration.receiverAppId);
    final launchedApps = launchRes['applications'] as List<dynamic>?;
    if (launchedApps != null && launchedApps.isNotEmpty) {
      final app = launchedApps.first as Map<String, dynamic>;
      _sessionId = app['sessionId'] as String?;
      _transportId = app['transportId'] as String?;
    }
    if (_transportId != null) {
      _connectTransport(_transportId!);
    }
  }

  Future<Map<String, dynamic>> _getReceiverStatus() async {
    final reqId = _nextRequestId();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[reqId] = completer;

    _sendJson(
      namespace: CastNamespaces.receiver,
      destinationId: CastNamespaces.defaultReceiverId,
      json: {'type': 'GET_STATUS', 'requestId': reqId},
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> _launchApp(String appId) async {
    final reqId = _nextRequestId();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[reqId] = completer;

    _sendJson(
      namespace: CastNamespaces.receiver,
      destinationId: CastNamespaces.defaultReceiverId,
      json: {'type': 'LAUNCH', 'appId': appId, 'requestId': reqId},
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => <String, dynamic>{},
    );
  }

  Future<void> _sendMediaCommand({
    required String type,
    Map<String, dynamic>? extra,
  }) async {
    final transportId = _transportId;
    final mediaSessionId = _mediaSessionId;
    if (transportId == null || mediaSessionId == null) return;

    final reqId = _nextRequestId();
    final payload = <String, dynamic>{
      'type': type,
      'requestId': reqId,
      'mediaSessionId': mediaSessionId,
    };
    if (extra != null) {
      payload.addAll(extra);
    }

    _sendJson(
      namespace: CastNamespaces.media,
      destinationId: transportId,
      json: payload,
    );
  }

  void _connectTransport(String destinationId) {
    _sendJson(
      namespace: CastNamespaces.connection,
      destinationId: destinationId,
      json: {'type': 'CONNECT'},
    );
  }

  void _startHeartbeat() {
    _lastPongTime = DateTime.now();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(configuration.heartbeatInterval, (_) {
      final elapsed = DateTime.now().difference(_lastPongTime);
      if (elapsed > configuration.heartbeatTimeout) {
        disconnect();
        return;
      }
      _sendJson(
        namespace: CastNamespaces.heartbeat,
        destinationId: CastNamespaces.defaultReceiverId,
        json: {'type': 'PING'},
      );
    });
  }

  void _onMessageReceived(CastMessage message) {
    if (message.payloadUtf8 == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.payloadUtf8!) as Map<String, dynamic>;
    } on Object catch (_) {
      return;
    }

    final type = data['type'] as String?;
    if (message.namespace == CastNamespaces.heartbeat) {
      if (type == 'PING') {
        _sendJson(
          namespace: CastNamespaces.heartbeat,
          destinationId: CastNamespaces.defaultReceiverId,
          json: {'type': 'PONG'},
        );
      } else if (type == 'PONG') {
        _lastPongTime = DateTime.now();
      }
      return;
    }

    final requestId = data['requestId'] as int?;
    if (requestId != null && _pendingRequests.containsKey(requestId)) {
      final completer = _pendingRequests.remove(requestId)!;
      final statusMap = data['status'] is Map<String, dynamic>
          ? data['status'] as Map<String, dynamic>
          : data;
      completer.complete(statusMap);
    }

    if (message.namespace == CastNamespaces.media && type == 'MEDIA_STATUS') {
      _handleMediaStatusMessage(data);
    }
  }

  void _handleMediaStatusMessage(Map<String, dynamic> data) {
    final statuses = data['status'] as List<dynamic>?;
    if (statuses == null || statuses.isEmpty) return;

    final statusMap = statuses.first as Map<String, dynamic>;
    final status = CastMediaStatus.fromJson(statusMap);
    _mediaSessionId = status.mediaSessionId;
    _lastMediaStatus = status;
    _mediaStatusController.add(status);
  }

  void _onSocketError(Object error) {
    disconnect();
  }

  void _onSocketDone() {
    disconnect();
  }

  void _sendJson({
    required String namespace,
    required String destinationId,
    required Map<String, dynamic> json,
  }) {
    final socket = _socket;
    if (socket == null) return;

    final message = CastMessage(
      sourceId: CastNamespaces.defaultSenderId,
      destinationId: destinationId,
      namespace: namespace,
      payloadUtf8: jsonEncode(json),
    );
    socket.send(message);
  }

  int _nextRequestId() => _requestId++;

  void _setState(CastSessionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }
}
