import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:better_player_cast/better_player_cast.dart';

/// Plain TCP [CastSocket] implementation for local loopback E2E testing.
class E2ECastTcpSocket implements CastSocket {
  E2ECastTcpSocket._(this._socket) {
    _socketSubscription = _socket.listen(
      _onData,
      onError: _messageController.addError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  final Socket _socket;
  final CastMessageCodec _codec = CastMessageCodec();
  final List<int> _buffer = <int>[];
  final StreamController<CastMessage> _messageController =
      StreamController<CastMessage>.broadcast();
  late final StreamSubscription<Uint8List> _socketSubscription;

  /// Connects to a loopback Cast mock server via plain TCP.
  static Future<E2ECastTcpSocket> connect({
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: timeout,
    );
    return E2ECastTcpSocket._(socket);
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
