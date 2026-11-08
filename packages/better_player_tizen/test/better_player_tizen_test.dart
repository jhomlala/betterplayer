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

    test('buildView returns Texture widget', () {
      final widget = tizenPlatform.buildView(42);
      expect(widget, isA<Texture>());
      expect((widget as Texture).textureId, 42);
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
        await tizenPlatform.enablePictureInPicture(42, 0, 0, 100, 100);
        await tizenPlatform.disablePictureInPicture(42);
        await tizenPlatform.setTrackParameters(42, 1920, 1080, 5000000);
        await tizenPlatform.setAudioTrack(42, 'English', 0);
        await tizenPlatform.setTextTrack(42, 'Subtitles', 0);
        await tizenPlatform.setMixWithOthers(42, true);
        await tizenPlatform.setAndroidMatchFrameRate(42, true);
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

  group('PlayerTizenController Tests', () {
    late StreamController<dynamic> rawEvents;
    late PlayerTizenController controller;
    final recordedCalls = <MethodCall>[];

    setUp(() {
      recordedCalls.clear();
      rawEvents = StreamController<dynamic>.broadcast();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            (call) async {
              recordedCalls.add(call);
              if (call.method == 'getPosition') {
                return 4500;
              }
              return null;
            },
          );

      controller = PlayerTizenController(
        textureId: 7,
        rawEventStream: rawEvents.stream,
      );
    });

    tearDown(() async {
      await controller.dispose();
      await rawEvents.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_tizen'),
            null,
          );
    });

    test('invokes method channel calls with correct parameters', () async {
      await controller.setDataSource(
        DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/stream.m3u8',
          headers: <String, String>{'Cookie': 'session=abc'},
        ),
      );
      await controller.play();
      await controller.pause();
      await controller.setVolume(0.8);
      await controller.setSpeed(1.25);
      await controller.seekTo(const Duration(seconds: 12));
      final pos = await controller.getPosition();
      expect(pos, const Duration(milliseconds: 4500));
      await controller.setLooping(looping: true);

      final methods = recordedCalls.map((c) => c.method).toList();
      expect(
        methods,
        containsAll(<String>[
          'setDataSource',
          'play',
          'pause',
          'setVolume',
          'setSpeed',
          'seekTo',
          'getPosition',
          'setLooping',
        ]),
      );
    });

    test(
      'setDataSource throws PlatformException when uri is null or empty',
      () async {
        await expectLater(
          controller.setDataSource(
            DataSource(sourceType: DataSourceType.network, uri: ''),
          ),
          throwsA(isA<PlatformException>()),
        );
      },
    );

    test('processes initialized event correctly', () async {
      final futureEvent = controller.events.first;
      rawEvents.add(<String, dynamic>{
        'event': 'initialized',
        'duration': 60000,
        'width': 1920,
        'height': 1080,
      });

      final event = await futureEvent;
      expect(event.eventType, VideoEventType.initialized);
      expect(event.duration, const Duration(seconds: 60));
      expect(event.size, const Size(1920, 1080));
    });

    test('processes completed event correctly', () async {
      final futureEvent = controller.events.first;
      rawEvents.add(<String, dynamic>{'event': 'completed'});

      final event = await futureEvent;
      expect(event.eventType, VideoEventType.completed);
    });

    test('processes bufferingUpdate event correctly', () async {
      final futureEvent = controller.events.first;
      rawEvents.add(<String, dynamic>{
        'event': 'bufferingUpdate',
        'values': <dynamic>[
          <int>[0, 15000],
        ],
      });

      final event = await futureEvent;
      expect(event.eventType, VideoEventType.bufferingUpdate);
      expect(event.buffered, hasLength(1));
      expect(event.buffered!.first.end, const Duration(seconds: 15));
    });

    test('processes isPlayingStateUpdate correctly', () async {
      final eventsFuture = controller.events.take(2).toList();
      rawEvents
        ..add(<String, dynamic>{
          'event': 'isPlayingStateUpdate',
          'isPlaying': true,
        })
        ..add(<String, dynamic>{
          'event': 'isPlayingStateUpdate',
          'isPlaying': false,
        });

      final events = await eventsFuture;
      expect(events[0].eventType, VideoEventType.play);
      expect(events[1].eventType, VideoEventType.pause);
    });
  });
}
