import 'dart:async';

import 'package:better_player_cast/better_player_cast.dart';

/// In-memory fake socket for testing CastV2 protocols.
class FakeCastSocket implements CastSocket {
  final StreamController<CastMessage> _incomingController =
      StreamController<CastMessage>.broadcast();
  final List<CastMessage> sentMessages = <CastMessage>[];
  bool isClosed = false;

  @override
  Stream<CastMessage> get messages => _incomingController.stream;

  @override
  void send(CastMessage message) {
    sentMessages.add(message);
  }

  /// Simulates receiving a [CastMessage] from the remote receiver.
  void simulateIncoming(CastMessage message) {
    _incomingController.add(message);
  }

  @override
  Future<void> close() async {
    isClosed = true;
    await _incomingController.close();
  }
}
