import 'dart:async';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:better_player_tizen/src/player_tizen.dart';
import 'package:better_player_tizen/src/player_tizen_controller.dart';
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

    setUp(() {
      logEntries.clear();
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
      when(
        () => mockPlayer.setTrackParameters(
          width: any(named: 'width'),
          height: any(named: 'height'),
          bitrate: any(named: 'bitrate'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockPlayer.setDataSource(any())).thenAnswer((_) async {});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            (methodCall) async {
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

    test('buildView returns Texture widget', () {
      final widget = tizenPlatform.buildView(42);
      expect(widget, isA<Texture>());
      final texture = widget as Texture;
      expect(texture.textureId, 42);
    });

    test('create initializes player and returns textureId', () async {
      final textureId = await tizenPlatform.create();
      expect(textureId, 42);
      expect(tizenPlatform.getPlayer(42), mockPlayer);
    });

    test('create throws PlatformException if textureId is missing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            (methodCall) async => <String, dynamic>{},
          );

      expect(() => tizenPlatform.create(), throwsA(isA<PlatformException>()));
    });

    test('dispose unregisters and calls dispose on player', () async {
      await tizenPlatform.create();
      await tizenPlatform.dispose(42);
      verify(() => mockPlayer.dispose()).called(1);
      expect(tizenPlatform.getPlayer(42), isNull);
    });

    test('dispose ignores null textureId', () async {
      await tizenPlatform.dispose(null);
      verifyNever(() => mockPlayer.dispose());
    });

    test('setDataSource delegates to player', () async {
      await tizenPlatform.create();
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/test.mp4',
      );
      await tizenPlatform.setDataSource(42, dataSource);
      verify(() => mockPlayer.setDataSource(dataSource)).called(1);
    });

    test('play and pause delegate to player', () async {
      await tizenPlatform.create();
      await tizenPlatform.play(42);
      verify(() => mockPlayer.play()).called(1);

      await tizenPlatform.pause(42);
      verify(() => mockPlayer.pause()).called(1);
    });

    test('setVolume and setSpeed delegate to player', () async {
      await tizenPlatform.create();
      await tizenPlatform.setVolume(42, 0.8);
      verify(() => mockPlayer.setVolume(0.8)).called(1);

      await tizenPlatform.setSpeed(42, 1.5);
      verify(() => mockPlayer.setSpeed(1.5)).called(1);
    });

    test('seekTo delegates to player', () async {
      await tizenPlatform.create();
      await tizenPlatform.seekTo(42, const Duration(seconds: 12));
      verify(() => mockPlayer.seekTo(const Duration(seconds: 12))).called(1);
    });

    test('seekTo ignores null position', () async {
      await tizenPlatform.create();
      await tizenPlatform.seekTo(42, null);
      verifyNever(() => mockPlayer.seekTo(any()));
    });

    test('getPosition returns player position', () async {
      await tizenPlatform.create();
      final position = await tizenPlatform.getPosition(42);
      expect(position, const Duration(seconds: 10));
    });

    test('getPosition returns Duration.zero for unknown player', () async {
      final position = await tizenPlatform.getPosition(999);
      expect(position, Duration.zero);
    });

    test('getAbsolutePosition returns null', () async {
      final absolute = await tizenPlatform.getAbsolutePosition(42);
      expect(absolute, isNull);
    });

    test('setLooping delegates to player', () async {
      await tizenPlatform.create();
      await tizenPlatform.setLooping(42, true);
      verify(() => mockPlayer.setLooping(looping: true)).called(1);
    });

    test('setTrackParameters delegates to player', () async {
      await tizenPlatform.create();
      await tizenPlatform.setTrackParameters(42, 1920, 1080, 5000000);
      verify(
        () => mockPlayer.setTrackParameters(
          width: 1920,
          height: 1080,
          bitrate: 5000000,
        ),
      ).called(1);
    });

    test('videoEventsFor returns player events stream', () {
      tizenPlatform.registerPlayer(textureId: 42, player: mockPlayer);
      expect(tizenPlatform.videoEventsFor(42), eventController.stream);
    });

    test('videoEventsFor returns empty stream for unknown player', () {
      expect(tizenPlatform.videoEventsFor(999), emitsDone);
    });

    test('isPictureInPictureSupported returns false', () async {
      final supported = await tizenPlatform.isPictureInPictureSupported(42);
      expect(supported, isFalse);
    });

    test('clearCache, preCache, stopPreCache complete safely', () async {
      await tizenPlatform.clearCache();
      await tizenPlatform.preCache(
        DataSource(sourceType: DataSourceType.network, uri: 'uri'),
        1024,
      );
      await tizenPlatform.stopPreCache('url', 'key');
    });
  });

  group('PlayerTizenController Tests', () {
    late StreamController<dynamic> rawEventController;
    final methodCalls = <MethodCall>[];

    setUp(() {
      methodCalls.clear();
      rawEventController = StreamController<dynamic>.broadcast();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            (methodCall) async {
              methodCalls.add(methodCall);
              if (methodCall.method == 'getPosition') {
                return 4500;
              }
              return null;
            },
          );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            null,
          );
      await rawEventController.close();
    });

    test('invokes method channel calls with correct parameters', () async {
      final controller = PlayerTizenController(
        textureId: 10,
        rawEventStream: rawEventController.stream,
      );

      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/stream.m3u8',
        headers: <String, String>{'Authorization': 'Bearer test'},
      );
      await controller.setDataSource(dataSource);
      await controller.play();
      await controller.pause();
      await controller.setVolume(0.75);
      await controller.setSpeed(1.25);
      await controller.seekTo(const Duration(seconds: 8));
      final pos = await controller.getPosition();
      await controller.setLooping(looping: true);
      await controller.setTrackParameters(
        width: 1280,
        height: 720,
        bitrate: 2500000,
      );
      await controller.dispose();

      expect(pos, const Duration(milliseconds: 4500));
      expect(methodCalls.map((c) => c.method), <String>[
        'setDataSource',
        'play',
        'pause',
        'setVolume',
        'setSpeed',
        'seekTo',
        'getPosition',
        'setLooping',
        'setTrackParameters',
        'dispose',
      ]);
    });

    test('processes initialized event correctly', () async {
      final controller = PlayerTizenController(
        textureId: 10,
        rawEventStream: rawEventController.stream,
      );

      final events = <VideoEvent>[];
      final subscription = controller.events.listen(events.add);

      rawEventController.add(<String, dynamic>{
        'event': 'initialized',
        'duration': 120000,
        'width': 1920,
        'height': 1080,
      });
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first.eventType, VideoEventType.initialized);
      expect(events.first.duration, const Duration(milliseconds: 120000));
      expect(events.first.size, const Size(1920, 1080));

      await subscription.cancel();
      await controller.dispose();
    });

    test('processes completed event correctly', () async {
      final controller = PlayerTizenController(
        textureId: 10,
        rawEventStream: rawEventController.stream,
      );

      final events = <VideoEvent>[];
      final subscription = controller.events.listen(events.add);

      rawEventController.add(<String, dynamic>{'event': 'completed'});
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first.eventType, VideoEventType.completed);

      await subscription.cancel();
      await controller.dispose();
    });

    test('processes bufferingUpdate event correctly', () async {
      final controller = PlayerTizenController(
        textureId: 10,
        rawEventStream: rawEventController.stream,
      );

      final events = <VideoEvent>[];
      final subscription = controller.events.listen(events.add);

      rawEventController.add(<String, dynamic>{
        'event': 'bufferingUpdate',
        'values': <dynamic>[
          <int>[0, 30000],
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first.eventType, VideoEventType.bufferingUpdate);
      expect(events.first.buffered?.length, 1);
      expect(
        events.first.buffered?.first.end,
        const Duration(milliseconds: 30000),
      );

      await subscription.cancel();
      await controller.dispose();
    });

    test('processes isPlayingStateUpdate correctly', () async {
      final controller = PlayerTizenController(
        textureId: 10,
        rawEventStream: rawEventController.stream,
      );

      final events = <VideoEvent>[];
      final subscription = controller.events.listen(events.add);

      rawEventController.add(<String, dynamic>{
        'event': 'isPlayingStateUpdate',
        'isPlaying': true,
      });
      rawEventController.add(<String, dynamic>{
        'event': 'isPlayingStateUpdate',
        'isPlaying': false,
      });
      await Future<void>.delayed(Duration.zero);

      expect(events.length, 2);
      expect(events[0].eventType, VideoEventType.play);
      expect(events[1].eventType, VideoEventType.pause);

      await subscription.cancel();
      await controller.dispose();
    });
  });
}
