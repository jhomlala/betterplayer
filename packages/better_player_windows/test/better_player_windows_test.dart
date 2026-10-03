import 'dart:async';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_windows/better_player_windows.dart';
import 'package:better_player_windows/src/mpv/mpv_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBetterPlayerWindowsPlayer extends Mock
    implements BetterPlayerWindowsPlayer {}

class MockMethodChannel extends Mock implements MethodChannel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DataSource(sourceType: DataSourceType.network));
  });

  group('BetterPlayerWindows Tests', () {
    late BetterPlayerWindows windowsPlatform;
    late MockBetterPlayerWindowsPlayer mockPlayer;
    late StreamController<VideoEvent> eventController;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_windows'),
            (methodCall) async => null,
          );

      mockPlayer = MockBetterPlayerWindowsPlayer();
      eventController = StreamController<VideoEvent>.broadcast();

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
      ).thenAnswer((_) async => const Duration(seconds: 15));
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
      when(
        () => mockPlayer.setAudioTrack(
          name: any(named: 'name'),
          index: any(named: 'index'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockPlayer.setDataSource(any())).thenAnswer((_) async {});

      windowsPlatform = BetterPlayerWindows(
        playerFactory: ({bufferingConfiguration}) async => mockPlayer,
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_windows'),
            null,
          );
      await eventController.close();
    });

    test('registerWith sets instance', () {
      BetterPlayerWindows.registerWith();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerWindows>());
    });

    test('buildView returns Texture widget', () {
      final widget = windowsPlatform.buildView(42);
      expect(widget, isA<Texture>());
      final texture = widget as Texture;
      expect(texture.textureId, 42);
    });

    test('create initializes player and returns textureId', () async {
      final textureId = await windowsPlatform.create();
      expect(textureId, 42);
    });

    test('dispose cleans up player instance', () async {
      await windowsPlatform.create();
      await windowsPlatform.dispose(42);
      verify(() => mockPlayer.dispose()).called(1);
    });

    test('setDataSource forwards to player', () async {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
      );
      await windowsPlatform.create();
      await windowsPlatform.setDataSource(42, dataSource);
      verify(() => mockPlayer.setDataSource(dataSource)).called(1);
    });

    test('playback controls forward to player', () async {
      await windowsPlatform.create();

      await windowsPlatform.play(42);
      verify(() => mockPlayer.play()).called(1);

      await windowsPlatform.pause(42);
      verify(() => mockPlayer.pause()).called(1);

      await windowsPlatform.setVolume(42, 0.8);
      verify(() => mockPlayer.setVolume(0.8)).called(1);

      await windowsPlatform.setSpeed(42, 1.5);
      verify(() => mockPlayer.setSpeed(1.5)).called(1);

      await windowsPlatform.seekTo(42, const Duration(seconds: 30));
      verify(() => mockPlayer.seekTo(const Duration(seconds: 30))).called(1);

      final pos = await windowsPlatform.getPosition(42);
      expect(pos, const Duration(seconds: 15));

      await windowsPlatform.setLooping(42, true);
      verify(() => mockPlayer.setLooping(looping: true)).called(1);

      await windowsPlatform.setTrackParameters(42, 1920, 1080, 5000);
      verify(
        () => mockPlayer.setTrackParameters(
          width: 1920,
          height: 1080,
          bitrate: 5000,
        ),
      ).called(1);

      await windowsPlatform.setAudioTrack(42, 'English', 1);
      verify(
        () => mockPlayer.setAudioTrack(name: 'English', index: 1),
      ).called(1);
    });

    test('videoEventsFor emits player events', () async {
      await windowsPlatform.create();
      final stream = windowsPlatform.videoEventsFor(42);

      final expectedEvent = VideoEvent(
        eventType: VideoEventType.play,
        key: 'test',
      );

      expectLater(stream, emits(expectedEvent));
      eventController.add(expectedEvent);
    });

    test('setupLogCallback receives log messages', () async {
      String? loggedMessage;
      int? loggedLevel;

      await windowsPlatform.setupLogCallback(({
        required int levelIndex,
        required String message,
      }) {
        loggedLevel = levelIndex;
        loggedMessage = message;
      });

      await windowsPlatform.create();
      expect(loggedMessage, contains('Created player with textureId: 42'));
      expect(loggedLevel, 1);
    });

    test('picture-in-picture methods handle Windows gracefully', () async {
      final supported = await windowsPlatform.isPictureInPictureSupported(42);
      expect(supported, isFalse);

      await expectLater(
        windowsPlatform.enablePictureInPicture(42, 0, 0, 100, 100),
        completes,
      );
      await expectLater(windowsPlatform.disablePictureInPicture(42), completes);
    });

    test(
      'no-op and unsupported methods log information and complete gracefully',
      () async {
        final logs = <String>[];
        await windowsPlatform.setupLogCallback(({
          required int levelIndex,
          required String message,
        }) {
          logs.add(message);
        });

        await windowsPlatform.create(
          bufferingConfiguration: const BufferingConfiguration(),
        );
        expect(
          logs.any(
            (l) => l.contains('BufferingConfiguration is ignored on Windows'),
          ),
          isTrue,
        );

        final absPos = await windowsPlatform.getAbsolutePosition(42);
        expect(absPos, isNull);
        expect(logs.any((l) => l.contains('getAbsolutePosition')), isTrue);

        await windowsPlatform.setMixWithOthers(42, true);
        expect(logs.any((l) => l.contains('setMixWithOthers')), isTrue);

        await windowsPlatform.setAndroidMatchFrameRate(42, true);
        expect(logs.any((l) => l.contains('setAndroidMatchFrameRate')), isTrue);

        await windowsPlatform.clearCache();
        expect(logs.any((l) => l.contains('clearCache')), isTrue);

        await windowsPlatform.preCache(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video.mp4',
          ),
          1024,
        );
        expect(logs.any((l) => l.contains('preCache')), isTrue);

        await windowsPlatform.stopPreCache(
          'https://example.com/video.mp4',
          null,
        );
        expect(logs.any((l) => l.contains('stopPreCache')), isTrue);

        final pip = await windowsPlatform.isPictureInPictureSupported(42);
        expect(pip, isFalse);
        expect(
          logs.any((l) => l.contains('isPictureInPictureSupported')),
          isTrue,
        );
      },
    );
  });
}
