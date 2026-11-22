import 'package:better_player_cast/better_player_cast.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_cast_socket.dart';

void main() {
  group('CastSession', () {
    late FakeCastSocket fakeSocket;
    late CastSession session;
    const testDevice = CastDevice(
      id: 'test-tv',
      name: 'Test TV',
      host: '192.168.1.100',
    );

    setUp(() {
      fakeSocket = FakeCastSocket();
      session = CastSession(
        configuration: const CastConfiguration(
          heartbeatInterval: Duration(milliseconds: 50),
          heartbeatTimeout: Duration(milliseconds: 200),
          connectTimeout: Duration(milliseconds: 500),
        ),
        socketFactory: ({
          required host,
          required port,
          timeout = const Duration(seconds: 10),
        }) async => fakeSocket,
      );
    });

    tearDown(() async {
      await session.disconnect();
    });

    test('connects and launches receiver app', () async {
      final states = <CastSessionState>[];
      session.stateStream.listen(states.add);

      final connectFuture = session.connect(testDevice);

      // Wait a tick for GET_STATUS to be sent
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Socket should receive CONNECT and GET_STATUS
      expect(fakeSocket.sentMessages.length, greaterThanOrEqualTo(2));
      expect(
        fakeSocket.sentMessages[0].namespace,
        equals(CastNamespaces.connection),
      );
      expect(
        fakeSocket.sentMessages[1].namespace,
        equals(CastNamespaces.receiver),
      );

      // Simulate RECEIVER_STATUS showing no apps running
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.receiver,
          payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":1,"status":{"applications":[]}}',
        ),
      );

      // Wait a tick for LAUNCH to be sent
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final launchMsg = fakeSocket.sentMessages.firstWhere(
        (m) => m.payloadUtf8?.contains('LAUNCH') ?? false,
      );
      expect(launchMsg.payloadUtf8, contains('CC1AD845'));

      // Simulate LAUNCH response with transportId
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.receiver,
          payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":2,"status":{"applications":[{"appId":"CC1AD845","sessionId":"sess-1","transportId":"transport-1"}]}}',
        ),
      );

      await connectFuture;
      await Future<void>.delayed(Duration.zero);

      expect(session.isConnected, isTrue);
      expect(session.state, equals(CastSessionState.connected));
      expect(session.device?.id, equals('test-tv'));
      expect(states, contains(CastSessionState.connecting));
      expect(states, contains(CastSessionState.connected));
    });

    test('loads media and updates media status', () async {
      // Connect session first
      final connectFuture = session.connect(testDevice);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Quick launch
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.receiver,
          payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":1,"status":{"applications":[{"appId":"CC1AD845","sessionId":"sess-1","transportId":"transport-1"}]}}',
        ),
      );
      await connectFuture;

      // Load media
      const mediaInfo = CastMediaInfo(
        url: 'https://example.com/video.mp4',
        title: 'Sample Video',
      );

      final loadFuture = session.loadMedia(
        mediaInfo,
        startPosition: const Duration(seconds: 15),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final loadMsg = fakeSocket.sentMessages.firstWhere(
        (m) => m.payloadUtf8?.contains('LOAD') ?? false,
      );
      expect(loadMsg.destinationId, equals('transport-1'));
      expect(loadMsg.payloadUtf8, contains('https://example.com/video.mp4'));
      expect(loadMsg.payloadUtf8, contains('"currentTime":15.0'));

      // Simulate MEDIA_STATUS reply
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'transport-1',
          destinationId: 'sender-0',
          namespace: CastNamespaces.media,
          payloadUtf8: '{"type":"MEDIA_STATUS","requestId":2,"status":[{"mediaSessionId":123,"playerState":"PLAYING","currentTime":15.0,"media":{"duration":120.0}}]}',
        ),
      );

      final status = await loadFuture;
      expect(status?.mediaSessionId, equals(123));
      expect(status?.playerState, equals(CastPlayerState.playing));
      expect(status?.currentTime, equals(const Duration(seconds: 15)));
      expect(status?.duration, equals(const Duration(seconds: 120)));
    });

    test('play, pause, seek, setVolume, and stop dispatch correctly', () async {
      // Connect session
      final connectFuture = session.connect(testDevice);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.receiver,
          payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":1,"status":{"applications":[{"appId":"CC1AD845","sessionId":"sess-1","transportId":"transport-1"}]}}',
        ),
      );
      await connectFuture;

      // Set active mediaSessionId
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'transport-1',
          destinationId: 'sender-0',
          namespace: CastNamespaces.media,
          payloadUtf8: '{"type":"MEDIA_STATUS","status":[{"mediaSessionId":42,"playerState":"PLAYING","currentTime":5.0}]}',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Test PAUSE
      await session.pause();
      final pauseMsg = fakeSocket.sentMessages.last;
      expect(pauseMsg.payloadUtf8, contains('"type":"PAUSE"'));
      expect(pauseMsg.payloadUtf8, contains('"mediaSessionId":42'));

      // Test PLAY
      await session.play();
      final playMsg = fakeSocket.sentMessages.last;
      expect(playMsg.payloadUtf8, contains('"type":"PLAY"'));

      // Test SEEK
      await session.seek(const Duration(seconds: 45));
      final seekMsg = fakeSocket.sentMessages.last;
      expect(seekMsg.payloadUtf8, contains('"type":"SEEK"'));
      expect(seekMsg.payloadUtf8, contains('"currentTime":45.0'));

      // Test SET_VOLUME
      await session.setVolume(0.8, muted: false);
      final volMsg = fakeSocket.sentMessages.last;
      expect(volMsg.payloadUtf8, contains('"type":"SET_VOLUME"'));
      expect(volMsg.payloadUtf8, contains('"level":0.8'));

      // Test STOP
      await session.stop();
      final stopMsg = fakeSocket.sentMessages.last;
      expect(stopMsg.payloadUtf8, contains('"type":"STOP"'));
      expect(stopMsg.payloadUtf8, contains('sess-1'));
    });

    test('answers incoming heartbeat PING with PONG', () async {
      final connectFuture = session.connect(testDevice);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.receiver,
          payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":1,"status":{"applications":[{"appId":"CC1AD845","sessionId":"sess-1","transportId":"transport-1"}]}}',
        ),
      );
      await connectFuture;

      fakeSocket.sentMessages.clear();

      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.heartbeat,
          payloadUtf8: '{"type":"PING"}',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final pongMsg = fakeSocket.sentMessages.firstWhere(
        (m) =>
            m.namespace == CastNamespaces.heartbeat &&
            (m.payloadUtf8?.contains('PONG') ?? false),
      );
      expect(pongMsg.destinationId, equals('receiver-0'));
    });

    test('disconnect closes socket and cleans state', () async {
      final connectFuture = session.connect(testDevice);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.receiver,
          payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":1,"status":{"applications":[{"appId":"CC1AD845","sessionId":"sess-1","transportId":"transport-1"}]}}',
        ),
      );
      await connectFuture;
      await Future<void>.delayed(Duration.zero);

      expect(session.isConnected, isTrue);

      await session.disconnect();

      expect(session.isConnected, isFalse);
      expect(session.state, equals(CastSessionState.disconnected));
      expect(fakeSocket.isClosed, isTrue);
    });

    test(
      'automatically disconnects when receiver sends transport CLOSE',
      () async {
        final connectFuture = session.connect(testDevice);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        fakeSocket.simulateIncoming(
          const CastMessage(
            sourceId: 'receiver-0',
            destinationId: 'sender-0',
            namespace: CastNamespaces.receiver,
            payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":1,"status":{"applications":[{"appId":"CC1AD845","sessionId":"sess-1","transportId":"transport-1"}]}}',
          ),
        );
        await connectFuture;
        expect(session.isConnected, isTrue);

        fakeSocket.simulateIncoming(
          const CastMessage(
            sourceId: 'transport-1',
            destinationId: 'sender-0',
            namespace: CastNamespaces.connection,
            payloadUtf8: '{"type":"CLOSE"}',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(session.isConnected, isFalse);
        expect(session.state, equals(CastSessionState.disconnected));
      },
    );
  });
}
