import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:better_player_macos/better_player_macos.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objective_c/objective_c.dart' as objc;

class MockBetterPlayer extends Mock implements BetterPlayerWrapper {}

class MockCacheManager extends Mock {}

class TestBetterPlayerMacOS extends BetterPlayerMacOS {
  final MockBetterPlayer mockPlayer;
  final MockCacheManager mockCacheManager;

  TestBetterPlayerMacOS({
    required this.mockPlayer,
    required this.mockCacheManager,
  });

  @override
  Future<int?> create({BufferingConfiguration? bufferingConfiguration}) async {
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int? textureId) {
    return const Stream.empty();
  }

  @override
  BetterPlayerWrapper? getPlayer(int textureId) {
    if (textureId == 1) return mockPlayer;
    return null;
  }

  @override
  Object createCacheManager() {
    return mockCacheManager;
  }

  @override
  void clearLogCallback() {}
}

void main() {
  group('BetterPlayerMacOS tests', () {
    late TestBetterPlayerMacOS macosPlayer;
    late MockBetterPlayer mockPlayer;
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockPlayer = MockBetterPlayer();
      mockCacheManager = MockCacheManager();
      macosPlayer = TestBetterPlayerMacOS(
        mockPlayer: mockPlayer,
        mockCacheManager: mockCacheManager,
      );

      final frame = pkg_ffi.calloc.allocate<objc.CGRect>(
        ffi.sizeOf<objc.CGRect>(),
      );
      registerFallbackValue(frame.ref);

      when(() => mockPlayer.position()).thenReturn(5000);
      when(() => mockPlayer.absolutePosition()).thenReturn(1600000000000);
    });

    test('registerWith sets instance', () {
      BetterPlayerMacOS.registerWith();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerMacOS>());
    });

    test('buildView returns AppKitView widget', () {
      final widget = macosPlayer.buildView(1);
      expect(widget, isA<AppKitView>());
      final appKitView = widget as AppKitView;
      expect(appKitView.viewType, 'better_player_view');
      expect(appKitView.creationParams, {'textureId': 1});
    });

    test('dispose calls native dispose', () async {
      await macosPlayer.create();
      await macosPlayer.dispose(1);
      verify(() => mockPlayer.dispose()).called(1);
    });

    test('create stores streams and returns textureId', () async {
      final textureId = await macosPlayer.create();
      expect(textureId, 1);
    });

    test(
      'play, pause, setVolume, setSpeed, setTrackParameters, setAudioTrack, setMixWithOthers, PiP interact with player',
      () async {
        await macosPlayer.create();

        await macosPlayer.play(1);
        verify(() => mockPlayer.play()).called(1);

        await macosPlayer.pause(1);
        verify(() => mockPlayer.pause()).called(1);

        await macosPlayer.setVolume(1, 0.5);
        verify(() => mockPlayer.setVolume(0.5)).called(1);

        await macosPlayer.setSpeed(1, 1.5);
        verify(() => mockPlayer.setSpeed(1.5)).called(1);

        await macosPlayer.setTrackParameters(1, 1920, 1080, 5000);
        verify(
          () => mockPlayer.setTrackParameters(
            width: 1920,
            height: 1080,
            bitrate: 5000,
          ),
        ).called(1);

        await macosPlayer.setAudioTrack(1, 'eng', 1);
        verify(
          () => mockPlayer.setAudioTrack(name: 'eng', index: 1),
        ).called(1);

        await macosPlayer.setTextTrack(1, 'eng', 1);
        verify(
          () => mockPlayer.setTextTrack(name: 'eng', index: 1),
        ).called(1);

        await macosPlayer.setMixWithOthers(1, true);
        verify(
          () => mockPlayer.setMixWithOthers(mixWithOthers: true),
        ).called(1);

        await macosPlayer.enablePictureInPicture(1, 0, 0, 100, 100);
        verify(() => mockPlayer.enablePictureInPicture(any())).called(1);

        await macosPlayer.disablePictureInPicture(1);
        verify(() => mockPlayer.disablePictureInPicture()).called(1);
      },
    );

    test('getAbsolutePosition returns correct value', () async {
      await macosPlayer.create();
      final absPos = await macosPlayer.getAbsolutePosition(1);
      expect(absPos, DateTime.fromMillisecondsSinceEpoch(1600000000000));

      when(
        () => mockPlayer.absolutePosition(),
      ).thenReturn(8640000000000000);
      expect(
        await macosPlayer.getAbsolutePosition(1),
        DateTime.fromMillisecondsSinceEpoch(8640000000000000),
      );

      when(
        () => mockPlayer.absolutePosition(),
      ).thenReturn(8640000000000001);
      expect(await macosPlayer.getAbsolutePosition(1), isNull);

      when(() => mockPlayer.absolutePosition()).thenReturn(0);
      expect(await macosPlayer.getAbsolutePosition(1), isNull);

      when(() => mockPlayer.absolutePosition()).thenReturn(-5000);
      expect(await macosPlayer.getAbsolutePosition(1), isNull);

      expect(await macosPlayer.getAbsolutePosition(null), isNull);
      expect(await macosPlayer.getAbsolutePosition(999), isNull);
    });

    test('seekTo calls seekTo in ms', () async {
      await macosPlayer.create();
      await macosPlayer.seekTo(1, const Duration(seconds: 5));
      verify(() => mockPlayer.seekTo(5000)).called(1);
    });

    test('setLooping interacts with player', () async {
      await macosPlayer.create();
      await macosPlayer.setLooping(1, true);
      verify(() => mockPlayer.setLooping(looping: true)).called(1);
    });

    test('getPosition returns correct value', () async {
      await macosPlayer.create();

      final pos = await macosPlayer.getPosition(1);
      expect(pos, const Duration(milliseconds: 5000));
    });

    test('videoEventsFor returns stream', () async {
      await macosPlayer.create();
      final stream = macosPlayer.videoEventsFor(1);
      expect(stream, isA<Stream<VideoEvent>>());
    });

    test('setDataSource handles DASH without throwing', () async {
      await macosPlayer.create();
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mpd',
      );

      expect(macosPlayer.setDataSource(1, dataSource), completes);
    });

    test(
      'setDataSource successfully delegates network URL to wrapper',
      () async {
        await macosPlayer.create();
        await macosPlayer.setDataSource(
          1,
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://test.com',
          ),
        );
        verify(
          () => mockPlayer.setDataSourceURLString(
            url: 'https://test.com',
            key: any(named: 'key'),
            certificateUrl: any(named: 'certificateUrl'),
            licenseUrl: any(named: 'licenseUrl'),
            useCache: any(named: 'useCache'),
            cacheKey: any(named: 'cacheKey'),
            cacheManager: any(named: 'cacheManager'),
            overriddenDuration: any(named: 'overriddenDuration'),
            videoExtension: any(named: 'videoExtension'),
          ),
        ).called(1);
      },
    );

    test(
      'setDataSource with file source successfully delegates to wrapper with file:// URI',
      () async {
        await macosPlayer.create();
        await macosPlayer.setDataSource(
          1,
          DataSource(
            sourceType: DataSourceType.file,
            uri: 'file:///path/to/video.mp4',
          ),
        );
        verify(
          () => mockPlayer.setDataSourceURLString(
            url: 'file:///path/to/video.mp4',
            key: any(named: 'key'),
            certificateUrl: any(named: 'certificateUrl'),
            licenseUrl: any(named: 'licenseUrl'),
            useCache: any(named: 'useCache'),
            cacheKey: any(named: 'cacheKey'),
            cacheManager: any(named: 'cacheManager'),
            overriddenDuration: any(named: 'overriddenDuration'),
            videoExtension: any(named: 'videoExtension'),
          ),
        ).called(1);
      },
    );

    test('setDataSource successfully delegates Asset to wrapper', () async {
      await macosPlayer.create();
      await macosPlayer.setDataSource(
        1,
        DataSource(sourceType: DataSourceType.asset, asset: 'asset.mp4'),
      );
      verify(
        () => mockPlayer.setDataSourceAsset(
          asset: 'asset.mp4',
          key: any(named: 'key'),
          cacheManager: any(named: 'cacheManager'),
          overriddenDuration: any(named: 'overriddenDuration'),
        ),
      ).called(1);
    });

    test(
      'handleInitialized emits initialized first, changedSize on positive size updates, and ignores non-positive dimensions',
      () async {
        final controller = StreamController<VideoEvent>.broadcast();
        macosPlayer.setEventControllerForTesting(
          textureId: 1,
          controller: controller,
        );

        final events = <VideoEvent>[];
        final subscription = controller.stream.listen(events.add);

        // 1. Initial zero size emits initialized
        macosPlayer.handleInitialized(
          textureId: 1,
          durationMs: 5000,
          width: 0,
          height: 0,
          key: 'streamKey',
        );
        await Future<void>.delayed(Duration.zero);
        expect(events.length, 1);
        expect(events[0].eventType, VideoEventType.initialized);
        expect(events[0].size, Size.zero);

        // 2. Duplicate zero or non-positive sizes are ignored
        for (final dims in [
          [0.0, 0.0],
          [0.0, 720.0],
          [1280.0, 0.0],
          [-100.0, -100.0],
        ]) {
          macosPlayer.handleInitialized(
            textureId: 1,
            durationMs: 5000,
            width: dims[0],
            height: dims[1],
            key: 'streamKey',
          );
          await Future<void>.delayed(Duration.zero);
          expect(events.length, 1);
        }

        // 3. Positive size updates emit changedSize with preserved metadata
        macosPlayer.handleInitialized(
          textureId: 1,
          durationMs: 5000,
          width: 1920,
          height: 1080,
          key: 'streamKey',
        );
        await Future<void>.delayed(Duration.zero);

        expect(events.length, 2);
        expect(events[1].eventType, VideoEventType.changedSize);
        expect(events[1].size, const Size(1920, 1080));
        expect(events[1].key, 'streamKey');
        expect(events[1].duration, const Duration(milliseconds: 5000));

        await subscription.cancel();
        await controller.close();
      },
    );

    test(
      'setDataSource and dispose reset initialization tracking',
      () async {
        final controller = StreamController<VideoEvent>.broadcast();
        macosPlayer.setEventControllerForTesting(
          textureId: 1,
          controller: controller,
        );

        final events = <VideoEvent>[];
        final subscription = controller.stream.listen(events.add);

        macosPlayer.handleInitialized(
          textureId: 1,
          durationMs: 1000,
          width: 1920,
          height: 1080,
          key: 'key1',
        );
        await Future<void>.delayed(Duration.zero);
        expect(events.last.eventType, VideoEventType.initialized);

        // setDataSource resets tracking
        await macosPlayer.setDataSource(
          1,
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://test.com',
          ),
        );

        macosPlayer.handleInitialized(
          textureId: 1,
          durationMs: 2000,
          width: 1280,
          height: 720,
          key: 'key2',
        );
        await Future<void>.delayed(Duration.zero);
        expect(events.length, 2);
        expect(events.last.eventType, VideoEventType.initialized);

        // dispose resets tracking
        await macosPlayer.dispose(1);
        final freshController = StreamController<VideoEvent>.broadcast();
        macosPlayer.setEventControllerForTesting(
          textureId: 1,
          controller: freshController,
        );
        final freshEvents = <VideoEvent>[];
        final freshSub = freshController.stream.listen(freshEvents.add);

        macosPlayer.handleInitialized(
          textureId: 1,
          durationMs: 3000,
          width: 640,
          height: 360,
          key: 'key3',
        );
        await Future<void>.delayed(Duration.zero);
        expect(freshEvents.length, 1);
        expect(freshEvents.last.eventType, VideoEventType.initialized);

        await subscription.cancel();
        await controller.close();
        await freshSub.cancel();
        await freshController.close();
      },
    );

    test(
      'dispose cleans up callbacks map and handles null textureId',
      () async {
        await macosPlayer.dispose(null);
        expect(macosPlayer.callbacks.containsKey(1), isFalse);

        await macosPlayer.dispose(1);
        expect(macosPlayer.callbacks.containsKey(1), isFalse);
      },
    );

    test(
      'cleanupOrphanedPlayers disposes players matching numeric keys',
      () {
        macosPlayer.cleanupOrphanedPlayers(playersOverride: {1: Object()});
        verify(() => mockPlayer.dispose()).called(1);
      },
    );

    test(
      'cleanupOrphanedPlayers ignores non-matching or empty player maps',
      () {
        macosPlayer.cleanupOrphanedPlayers(playersOverride: {});
        verifyNever(() => mockPlayer.dispose());

        macosPlayer.cleanupOrphanedPlayers(
          playersOverride: {'stringKey': Object()},
        );
        verifyNever(() => mockPlayer.dispose());
      },
    );
  });
}
