import 'dart:async';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_tizen/src/player_tizen_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('normalizes file:// URI to standard file path', () async {
      await controller.setDataSource(
        DataSource(
          sourceType: DataSourceType.file,
          uri: 'file:///opt/usr/media/sample.mp4',
        ),
      );

      final call = recordedCalls.firstWhere(
        (c) => c.method == 'setDataSource',
      );
      final args = call.arguments as Map;
      expect(args['uri'], '/opt/usr/media/sample.mp4');
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

    test('controller methods gracefully no-op when disposed', () async {
      await controller.dispose();
      final callCount = recordedCalls.length;
      await controller.play();
      await controller.pause();
      await controller.setVolume(0.5);
      await controller.setSpeed(1);
      await controller.seekTo(Duration.zero);
      await controller.setLooping(looping: true);
      expect(await controller.getPosition(), Duration.zero);
      expect(recordedCalls.length, callCount);
    });

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

    test(
      'processes bufferingStart and bufferingEnd events correctly',
      () async {
        final eventsFuture = controller.events.take(2).toList();
        rawEvents
          ..add(<String, dynamic>{'event': 'bufferingStart'})
          ..add(<String, dynamic>{'event': 'bufferingEnd'});

        final events = await eventsFuture;
        expect(events[0].eventType, VideoEventType.bufferingStart);
        expect(events[1].eventType, VideoEventType.bufferingEnd);
      },
    );

    test('processes changedSize event correctly', () async {
      final futureEvent = controller.events.first;
      rawEvents.add(<String, dynamic>{
        'event': 'changedSize',
        'width': 1280,
        'height': 720,
      });

      final event = await futureEvent;
      expect(event.eventType, VideoEventType.changedSize);
      expect(event.size, const Size(1280, 720));
    });

    test('processes seek event correctly', () async {
      final futureEvent = controller.events.first;
      rawEvents.add(<String, dynamic>{
        'event': 'seek',
        'position': 15000,
      });

      final event = await futureEvent;
      expect(event.eventType, VideoEventType.seek);
      expect(event.position, const Duration(milliseconds: 15000));
    });

    test('handles asset DataSource without uri', () async {
      await controller.setDataSource(
        DataSource(
          sourceType: DataSourceType.asset,
          asset: 'assets/sample.mp4',
        ),
      );

      final call = recordedCalls.firstWhere(
        (c) => c.method == 'setDataSource',
      );
      final args = call.arguments as Map;
      expect(args['uri'], 'assets/sample.mp4');
    });

    test('setSpeed clamps values within supported range', () async {
      await controller.setSpeed(0);
      await controller.setSpeed(15);

      final speedCalls = recordedCalls
          .where((c) => c.method == 'setSpeed')
          .toList();
      expect((speedCalls[0].arguments as Map)['speed'], 0.25);
      expect((speedCalls[1].arguments as Map)['speed'], 10.0);
    });
  });
}
