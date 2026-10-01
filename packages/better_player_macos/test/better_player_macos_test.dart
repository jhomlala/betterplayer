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

  TestBetterPlayerMacOS(this.mockPlayer, this.mockCacheManager);

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
}

void main() {
  group('BetterPlayerMacOS tests', () {
    late TestBetterPlayerMacOS macosPlayer;
    late MockBetterPlayer mockPlayer;
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockPlayer = MockBetterPlayer();
      mockCacheManager = MockCacheManager();
      macosPlayer = TestBetterPlayerMacOS(mockPlayer, mockCacheManager);

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
          () =>
              mockPlayer.setTrackParameters(1920, height: 1080, bitrate: 5000),
        ).called(1);

        await macosPlayer.setAudioTrack(1, 'eng', 1);
        verify(() => mockPlayer.setAudioTrack('eng', index: 1)).called(1);

        await macosPlayer.setMixWithOthers(1, true);
        verify(() => mockPlayer.setMixWithOthers(true)).called(1);

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
      verify(() => mockPlayer.setLooping(true)).called(1);
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
            'https://test.com',
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
            'file:///path/to/video.mp4',
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
          'asset.mp4',
          key: any(named: 'key'),
          cacheManager: any(named: 'cacheManager'),
          overriddenDuration: any(named: 'overriddenDuration'),
        ),
      ).called(1);
    });
  });
}
