import 'package:better_player_cast/src/protocol/cast_message.dart';

/// Function signature for creating a [CastSocket] connection.
typedef CastSocketFactory = Future<CastSocket> Function({
  required String host,
  required int port,
  Duration timeout,
});

/// Bidirectional socket abstraction for sending and receiving [CastMessage]s.
abstract class CastSocket {
  /// Stream of incoming messages decoded from the socket.
  Stream<CastMessage> get messages;

  /// Sends a [CastMessage] over the wire.
  void send(CastMessage message);

  /// Closes the socket connection.
  Future<void> close();
}
