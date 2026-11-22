import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:better_player_cast/better_player_cast.dart';
import 'package:flutter/foundation.dart';

/// Lightweight in-memory loopback CastV2 mock server for deterministic Maestro E2E tests.
class E2ECastMockServer {
  ServerSocket? _serverSocket;
  final List<Socket> _clientSockets = [];
  final CastMessageCodec _codec = CastMessageCodec();
  final Map<Socket, List<int>> _clientBuffers = {};

  /// Observable list of received command types (e.g. ['CONNECT', 'LAUNCH', 'LOAD', 'PAUSE', 'STOP']).
  final ValueNotifier<List<String>> receivedCommands =
      ValueNotifier<List<String>>([]);

  /// Port on which this mock server is listening.
  int get port => _serverSocket?.port ?? 0;

  /// Starts the mock CastV2 TCP server on loopback.
  Future<void> start() async {
    _serverSocket = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    _serverSocket!.listen(_onClientConnected);
  }

  /// Stops the mock server and disconnects all clients.
  Future<void> stop() async {
    for (final socket in _clientSockets) {
      socket.destroy();
    }
    _clientSockets.clear();
    _clientBuffers.clear();
    await _serverSocket?.close();
    _serverSocket = null;
  }

  void _onClientConnected(Socket socket) {
    _clientSockets.add(socket);
    _clientBuffers[socket] = <int>[];

    socket.listen(
      (chunk) => _onData(socket, chunk),
      onDone: () {
        _clientSockets.remove(socket);
        _clientBuffers.remove(socket);
      },
      onError: (_) {
        _clientSockets.remove(socket);
        _clientBuffers.remove(socket);
      },
    );
  }

  void _onData(Socket socket, Uint8List chunk) {
    final buffer = _clientBuffers[socket];
    if (buffer == null) return;

    final messages = _codec.decodeMessages(
      chunk: chunk,
      buffer: buffer,
    );
    for (final message in messages) {
      _handleMessage(socket, message);
    }
  }

  void _handleMessage(Socket socket, CastMessage message) {
    if (message.payloadUtf8 == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.payloadUtf8!) as Map<String, dynamic>;
    } on Object catch (_) {
      return;
    }

    final type = data['type'] as String? ?? 'UNKNOWN';
    _recordCommand(type);

    final reqId = data['requestId'] as int? ?? 1;

    if (message.namespace == CastNamespaces.heartbeat) {
      if (type == 'PING') {
        _sendJson(
          socket,
          namespace: CastNamespaces.heartbeat,
          sourceId: 'receiver-0',
          destinationId: message.sourceId,
          json: {'type': 'PONG'},
        );
      }
      return;
    }

    if (message.namespace == CastNamespaces.receiver) {
      if (type == 'GET_STATUS') {
        _sendJson(
          socket,
          namespace: CastNamespaces.receiver,
          sourceId: 'receiver-0',
          destinationId: message.sourceId,
          json: {
            'type': 'RECEIVER_STATUS',
            'requestId': reqId,
            'status': {'applications': <dynamic>[]},
          },
        );
      } else if (type == 'LAUNCH') {
        _sendJson(
          socket,
          namespace: CastNamespaces.receiver,
          sourceId: 'receiver-0',
          destinationId: message.sourceId,
          json: {
            'type': 'RECEIVER_STATUS',
            'requestId': reqId,
            'status': {
              'applications': [
                {
                  'appId': 'CC1AD845',
                  'sessionId': 'e2e-session-1',
                  'transportId': 'e2e-transport-1',
                },
              ],
            },
          },
        );
      } else if (type == 'STOP') {
        _sendJson(
          socket,
          namespace: CastNamespaces.receiver,
          sourceId: 'receiver-0',
          destinationId: message.sourceId,
          json: {
            'type': 'RECEIVER_STATUS',
            'requestId': reqId,
            'status': {'applications': <dynamic>[]},
          },
        );
      }
      return;
    }

    if (message.namespace == CastNamespaces.media) {
      if (type == 'LOAD') {
        _sendJson(
          socket,
          namespace: CastNamespaces.media,
          sourceId: 'e2e-transport-1',
          destinationId: message.sourceId,
          json: {
            'type': 'MEDIA_STATUS',
            'requestId': reqId,
            'status': [
              {
                'mediaSessionId': 1,
                'playerState': 'PLAYING',
                'currentTime': 0.0,
                'media': {'duration': 120.0},
              },
            ],
          },
        );
      } else if (type == 'PAUSE') {
        _sendJson(
          socket,
          namespace: CastNamespaces.media,
          sourceId: 'e2e-transport-1',
          destinationId: message.sourceId,
          json: {
            'type': 'MEDIA_STATUS',
            'requestId': reqId,
            'status': [
              {
                'mediaSessionId': 1,
                'playerState': 'PAUSED',
                'currentTime': 0.0,
              },
            ],
          },
        );
      } else if (type == 'PLAY') {
        _sendJson(
          socket,
          namespace: CastNamespaces.media,
          sourceId: 'e2e-transport-1',
          destinationId: message.sourceId,
          json: {
            'type': 'MEDIA_STATUS',
            'requestId': reqId,
            'status': [
              {
                'mediaSessionId': 1,
                'playerState': 'PLAYING',
                'currentTime': 0.0,
              },
            ],
          },
        );
      }
    }
  }

  void _sendJson(
    Socket socket, {
    required String namespace,
    required String sourceId,
    required String destinationId,
    required Map<String, dynamic> json,
  }) {
    final message = CastMessage(
      sourceId: sourceId,
      destinationId: destinationId,
      namespace: namespace,
      payloadUtf8: jsonEncode(json),
    );
    final bytes = _codec.encodeMessage(message);
    socket.add(bytes);
  }

  void _recordCommand(String command) {
    final current = List<String>.from(receivedCommands.value);
    current.add(command);
    receivedCommands.value = current;
  }
}
