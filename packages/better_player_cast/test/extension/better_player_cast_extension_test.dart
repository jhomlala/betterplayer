import 'package:better_player/better_player.dart';
import 'package:better_player_cast/better_player_cast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_cast_discovery.dart';
import '../helpers/fake_cast_socket.dart';
import '../helpers/mock_better_player_platform.dart';

void main() {
  group('BetterPlayerCastExtension', () {
    late FakeCastSocket fakeSocket;
    late FakeCastDiscovery fakeDiscovery;
    late BetterPlayerCastExtension extension;
    late BetterPlayerController controller;

    const testDevice = CastDevice(
      id: 'dev-1',
      name: 'Living Room TV',
      host: '127.0.0.1',
    );

    setUp(() {
      BetterPlayerPlatform.instance = MockBetterPlayerPlatform();
      fakeSocket = FakeCastSocket();
      fakeDiscovery = FakeCastDiscovery();

      extension = BetterPlayerCastExtension(
        discovery: fakeDiscovery,
        socketFactory: ({
          required host,
          required port,
          timeout = const Duration(seconds: 10),
        }) async => fakeSocket,
      );

      controller = BetterPlayerController(
        PlayerConfiguration(
          extensions: [extension],
        ),
        betterPlayerDataSource: PlayerDataSource(
          DataSourceType.network,
          'https://example.com/test.mp4',
        ),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('registers on controller and reports cast state', () {
      expect(controller.hasCastExtension, isTrue);
      expect(controller.isCasting, isFalse);
      expect(controller.isExternalPlaybackSupported, isTrue);
      expect(extension.targetDeviceName, isNull);
    });

    testWidgets('shows cast picker bottom sheet and starts discovery', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final key = GlobalKey<NavigatorState>();
      final testExt = BetterPlayerCastExtension(
        navigatorKey: key,
        discovery: fakeDiscovery,
      );
      final testController = BetterPlayerController(
        PlayerConfiguration(extensions: [testExt]),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: testExt.showCastPicker,
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      expect(fakeDiscovery.isScanning, isFalse);

      await tester.tap(find.text('Open Picker'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeDiscovery.isScanning, isTrue);
      expect(find.byType(CastDevicePickerSheet), findsOneWidget);

      // Close picker
      Navigator.of(key.currentContext!).pop();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeDiscovery.isScanning, isFalse);
      testController.dispose();
    });

    test('forwards player events to CastSession when connected', () async {
      // Connect to fake socket
      final connectFuture = extension.session.connect(testDevice);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Simulate LAUNCH
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 'receiver-0',
          destinationId: 'sender-0',
          namespace: CastNamespaces.receiver,
          payloadUtf8: '{"type":"RECEIVER_STATUS","requestId":1,"status":{"applications":[{"appId":"CC1AD845","sessionId":"s1","transportId":"t1"}]}}',
        ),
      );
      await connectFuture;

      // Simulate MEDIA_STATUS to initialize active mediaSessionId
      fakeSocket.simulateIncoming(
        const CastMessage(
          sourceId: 't1',
          destinationId: 'sender-0',
          namespace: CastNamespaces.media,
          payloadUtf8: '{"type":"MEDIA_STATUS","status":[{"mediaSessionId":1,"playerState":"PLAYING","currentTime":5.0}]}',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(extension.isCasting, isTrue);
      expect(controller.isCasting, isTrue);
      expect(extension.targetDeviceName, equals('Living Room TV'));

      fakeSocket.sentMessages.clear();

      // Trigger play
      controller.postEvent(PlayerEvent(PlayerEventType.play));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Trigger pause
      controller.postEvent(PlayerEvent(PlayerEventType.pause));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Trigger seek
      controller.postEvent(
        PlayerEvent(
          PlayerEventType.seekTo,
          parameters: {'duration': const Duration(seconds: 30)},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Trigger volume
      controller.postEvent(
        PlayerEvent(
          PlayerEventType.setVolume,
          parameters: {'volume': 0.75},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final sentPayloads = fakeSocket.sentMessages
          .map((m) => m.payloadUtf8 ?? '')
          .toList();
      expect(sentPayloads.any((p) => p.contains('"type":"PLAY"')), isTrue);
      expect(sentPayloads.any((p) => p.contains('"type":"PAUSE"')), isTrue);
      expect(
        sentPayloads.any(
          (p) =>
              p.contains('"type":"SEEK"') && p.contains('"currentTime":30.0'),
        ),
        isTrue,
      );
      expect(
        sentPayloads.any(
          (p) =>
              p.contains('"type":"SET_VOLUME"') && p.contains('"level":0.75'),
        ),
        isTrue,
      );
    });

    test('ignores file data sources gracefully without throwing', () async {
      final fileController = BetterPlayerController(
        PlayerConfiguration(extensions: [extension]),
        betterPlayerDataSource: PlayerDataSource(
          DataSourceType.file,
          '/local/file.mp4',
        ),
      );

      // Trigger setupDataSource event
      fileController.postEvent(PlayerEvent(PlayerEventType.setupDataSource));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(extension.isCasting, isFalse);
      fileController.dispose();
    });
  });
}
