import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:better_player_cast/src/protocol/cast_message.dart';
import 'package:better_player_cast/src/protocol/cast_message_codec.dart';
import 'package:better_player_cast/src/protocol/cast_socket.dart';

/// [CastSocket] implementation using [SecureSocket] for TLS communication with Chromecast.
class CastTlsSocket implements CastSocket {
  CastTlsSocket._(this._socket) {
    _socketSubscription = _socket.listen(
      _onData,
      onError: _messageController.addError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  final SecureSocket _socket;
  final CastMessageCodec _codec = CastMessageCodec();
  final List<int> _buffer = <int>[];
  final StreamController<CastMessage> _messageController =
      StreamController<CastMessage>.broadcast();
  late final StreamSubscription<Uint8List> _socketSubscription;

  /// Connects to a Cast receiver host and port via TLS.
  static Future<CastTlsSocket> connect({
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final socket = await SecureSocket.connect(
      host,
      port,
      onBadCertificate: (_) => true,
      timeout: timeout,
    );
    return CastTlsSocket._(socket);
  }

  @override
  Stream<CastMessage> get messages => _messageController.stream;

  @override
  void send(CastMessage message) {
    final bytes = _codec.encodeMessage(message);
    _socket.add(bytes);
  }

  @override
  Future<void> close() async {
    await _socketSubscription.cancel();
    await _socket.close();
    _socket.destroy();
    await _messageController.close();
  }

  void _onData(Uint8List chunk) {
    try {
      final messages = _codec.decodeMessages(
        chunk: chunk,
        buffer: _buffer,
      );
      messages.forEach(_messageController.add);
    } on Object catch (error, stackTrace) {
      _messageController.addError(error, stackTrace);
    }
  }

  void _onDone() {
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
