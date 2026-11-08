import 'dart:async';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:better_player_tizen/src/player_tizen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlayerTizen extends Mock implements PlayerTizen {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DataSource(sourceType: DataSourceType.network));
  });

  group('BetterPlayerTizen Platform Tests', () {
    late BetterPlayerTizen tizenPlatform;
    late MockPlayerTizen mockPlayer;
    late StreamController<VideoEvent> eventController;
    final logEntries = <String>[];
    final methodCalls = <MethodCall>[];

    setUp(() {
      logEntries.clear();
      methodCalls.clear();
      eventController = StreamController<VideoEvent>.broadcast();
      mockPlayer = MockPlayerTizen();

      when(() => mockPlayer.textureId).thenReturn(42);
      when(() => mockPlayer.events).thenAnswer((_) => eventController.stream);
      when(() => mockPlayer.dispose()).thenAnswer((_) async {});
      when(() => mockPlayer.play()).thenAnswer((_) async {});
      when(() => mockPlayer.pause()).thenAnswer((_) async {});
      when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
      when(() => mockPlayer.setSpeed(any())).thenAnswer((_) async {});
      when(() => mockPlayer.seekTo(any())).thenAnswer((_) async {});
      when(
        () => mockPlayer.getPosition(),
      ).thenAnswer((_) async => const Duration(seconds: 10));
      when(
        () => mockPlayer.setLooping(looping: any(named: 'looping')),
      ).thenAnswer((_) async {});
      when(() => mockPlayer.setDataSource(any())).thenAnswer((_) async {});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            (methodCall) async {
              methodCalls.add(methodCall);
              if (methodCall.method == 'create') {
                return <String, dynamic>{'textureId': 42};
              }
              return null;
            },
          );

      tizenPlatform = BetterPlayerTizen(
        playerFactory: ({required textureId, bufferingConfiguration}) async =>
            mockPlayer,
      );
      tizenPlatform.setupLogCallback(({required levelIndex, required message}) {
        logEntries.add('[$levelIndex] $message');
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            null,
          );
      await eventController.close();
    });

    test('registerWith sets instance', () {
      BetterPlayerTizen.registerWith();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerTizen>());
    });

    test('register sets instance', () {
      BetterPlayerTizen.register();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerTizen>());
    });

    test('constructor invokes clear to clean up orphaned players', () {
      expect(methodCalls.any((c) => c.method == 'clear'), isTrue);
    });

    test('buildView returns Texture widget when textureId is valid', () {
      final widget = tizenPlatform.buildView(42);
      expect(widget, isA<Texture>());
      expect((widget as Texture).textureId, 42);
    });

    test('buildView returns custom widget when viewBuilder is provided', () {
      final customPlatform = BetterPlayerTizen(
        viewBuilder: (textureId) => Container(key: Key('custom_$textureId')),
      );
      final widget = customPlatform.buildView(42);
      expect(widget, isA<Container>());
      expect((widget as Container).key, const Key('custom_42'));
    });

    test('buildView returns SizedBox.shrink when textureId is null', () {
      final widget = tizenPlatform.buildView(null);
      expect(widget, isA<SizedBox>());
    });

    test('create initializes player and returns textureId', () async {
      final textureId = await tizenPlatform.create();
      expect(textureId, 42);
      expect(tizenPlatform.getPlayer(42), same(mockPlayer));
    });

    test('create throws PlatformException if textureId is missing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            (methodCall) async => <String, dynamic>{},
          );

      await expectLater(
        tizenPlatform.create(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('dispose unregisters and calls dispose on player', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      await tizenPlatform.dispose(42);
      verify(() => mockPlayer.dispose()).called(1);
      expect(tizenPlatform.getPlayer(42), isNull);
    });

    test('dispose ignores null textureId', () async {
      await tizenPlatform.dispose(null);
      verifyNever(() => mockPlayer.dispose());
    });

    test('dispose invokes native dispose for untracked player', () async {
      await tizenPlatform.dispose(999);
      expect(
        methodCalls.any(
          (c) =>
              c.method == 'dispose' && (c.arguments as Map)['textureId'] == 999,
        ),
        isTrue,
      );
    });

    test('setDataSource delegates to player', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
      );
      await tizenPlatform.setDataSource(42, dataSource);
      verify(() => mockPlayer.setDataSource(dataSource)).called(1);
    });

    test('play and pause delegate to player', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      await tizenPlatform.play(42);
      await tizenPlatform.pause(42);
      verify(() => mockPlayer.play()).called(1);
      verify(() => mockPlayer.pause()).called(1);
    });

    test('setVolume and setSpeed delegate to player', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      await tizenPlatform.setVolume(42, 0.5);
      await tizenPlatform.setSpeed(42, 1.5);
      verify(() => mockPlayer.setVolume(0.5)).called(1);
      verify(() => mockPlayer.setSpeed(1.5)).called(1);
    });

    test('seekTo delegates to player', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      const pos = Duration(seconds: 30);
      await tizenPlatform.seekTo(42, pos);
      verify(() => mockPlayer.seekTo(pos)).called(1);
    });

    test('seekTo ignores null position', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      await tizenPlatform.seekTo(42, null);
      verifyNever(() => mockPlayer.seekTo(any()));
    });

    test('getPosition returns player position', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      final position = await tizenPlatform.getPosition(42);
      expect(position, const Duration(seconds: 10));
    });

    test('getPosition returns Duration.zero for unknown player', () async {
      final position = await tizenPlatform.getPosition(999);
      expect(position, Duration.zero);
    });

    test('getAbsolutePosition returns null', () async {
      expect(await tizenPlatform.getAbsolutePosition(42), isNull);
    });

    test('setLooping delegates to player', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      await tizenPlatform.setLooping(42, true);
      verify(() => mockPlayer.setLooping(looping: true)).called(1);
    });

    test('videoEventsFor returns player events stream', () async {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      final stream = tizenPlatform.videoEventsFor(42);
      final futureEvent = stream.first;
      eventController.add(
        const VideoEvent(eventType: VideoEventType.play, key: '42'),
      );
      final received = await futureEvent;
      expect(received.eventType, VideoEventType.play);
    });

    test('videoEventsFor returns empty stream for unknown player', () async {
      final events = await tizenPlatform.videoEventsFor(999).toList();
      expect(events, isEmpty);
    });

    test(
      'unsupported platform methods complete safely without throwing',
      () async {
        expect(await tizenPlatform.isPictureInPictureSupported(42), isFalse);
        expect(await tizenPlatform.getAudioTracks(42), isEmpty);
        await tizenPlatform.enablePictureInPicture(42, 0, 0, 100, 100);
        await tizenPlatform.disablePictureInPicture(42);
        await tizenPlatform.setTrackParameters(42, 1920, 1080, 5000000);
        await tizenPlatform.setAudioTrack(42, 'English', 0);
        await tizenPlatform.setTextTrack(42, 'Subtitles', 0);
        await tizenPlatform.setMixWithOthers(42, true);
        await tizenPlatform.setAndroidMatchFrameRate(42, true);
        await tizenPlatform.setScreenCaptureProtection(enabled: true);
        await tizenPlatform.showExternalPlaybackPicker(textureId: 42);
        await tizenPlatform.clearCache();
        await tizenPlatform.preCache(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video.mp4',
          ),
          1024,
        );
        await tizenPlatform.stopPreCache('https://example.com/video.mp4', null);
        expect(logEntries, isNotEmpty);
      },
    );
  });
}
