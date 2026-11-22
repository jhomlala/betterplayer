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
      expect(extension.overlayWidget, isA<CastPlayerOverlay>());
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

    test('routes controller play, pause, seek, and volume to CastSession without recursive pause', () async {
      // Wait for MockBetterPlayerPlatform to emit initialized event
      await Future<void>.delayed(const Duration(milliseconds: 20));

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
          payloadUtf8: '{"type":"MEDIA_STATUS","status":[{"mediaSessionId":1,"playerState":"PLAYING","currentTime":5.0,"media":{"duration":120.0}}]}',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(extension.isCasting, isTrue);
      expect(controller.isCasting, isTrue);
      expect(extension.targetDeviceName, equals('Living Room TV'));
      expect(controller.isPlaying(), isTrue);
      expect(
        controller.videoPlayerValue?.duration,
        equals(const Duration(seconds: 120)),
      );

      fakeSocket.sentMessages.clear();

      // Trigger pause via controller
      await controller.pause();
      expect(controller.isPlaying(), isFalse);
      expect(fakeSocket.sentMessages.length, equals(1));
      expect(
        fakeSocket.sentMessages.single.payloadUtf8,
        contains('"type":"PAUSE"'),
      );

      fakeSocket.sentMessages.clear();

      // Trigger play via controller and verify no recursive PAUSE is sent
      await controller.play();
      expect(controller.isPlaying(), isTrue);
      expect(fakeSocket.sentMessages.length, equals(1));
      expect(
        fakeSocket.sentMessages.single.payloadUtf8,
        contains('"type":"PLAY"'),
      );

      fakeSocket.sentMessages.clear();

      // Trigger seek via controller
      await controller.seekTo(const Duration(seconds: 30));
      expect(
        fakeSocket.sentMessages.single.payloadUtf8,
        allOf(contains('"type":"SEEK"'), contains('"currentTime":30.0')),
      );
      expect(
        controller.videoPlayerValue?.position.inSeconds,
        closeTo(30, 1),
      );

      fakeSocket.sentMessages.clear();

      // Trigger volume via controller
      await controller.setVolume(0.75);
      expect(
        fakeSocket.sentMessages.single.payloadUtf8,
        allOf(contains('"type":"SET_VOLUME"'), contains('"level":0.75')),
      );
      expect(controller.videoPlayerValue?.volume, equals(0.75));
    });

    test('ignores file data sources gracefully without throwing', () async {
      final fileController = BetterPlayerController(
        PlayerConfiguration(extensions: [extension]),
        betterPlayerDataSource: PlayerDataSource(
          DataSourceType.file,
          '/local/file.mp4',
        ),
      );

      fileController.postEvent(PlayerEvent(PlayerEventType.setupDataSource));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(extension.isCasting, isFalse);
      fileController.dispose();
    });
  });
}
