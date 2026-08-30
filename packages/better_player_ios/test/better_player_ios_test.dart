import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:better_player_ios/better_player_ios.dart';
import 'package:better_player_ios/src/better_player_ios_ffi.g.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objective_c/objective_c.dart' as objc;

// Use dynamic typing so we don't need to implement the final FFI extension type
class MockBetterPlayer extends Mock implements BetterPlayerWrapper {}

class MockCacheManager extends Mock {}

class TestBetterPlayerIOS extends BetterPlayerIOS {
  final MockBetterPlayer mockPlayer;
  final MockCacheManager mockCacheManager;
  dynamic capturedCallback;

  TestBetterPlayerIOS(this.mockPlayer, this.mockCacheManager);

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
  group('BetterPlayerIOS tests', () {
    late TestBetterPlayerIOS iosPlayer;
    late MockBetterPlayer mockPlayer;
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockPlayer = MockBetterPlayer();
      mockCacheManager = MockCacheManager();
      iosPlayer = TestBetterPlayerIOS(mockPlayer, mockCacheManager);

      final frame = pkg_ffi.calloc.allocate<objc.CGRect>(
        ffi.sizeOf<objc.CGRect>(),
      );
      registerFallbackValue(frame.ref);

      when(() => mockPlayer.position()).thenReturn(5000);
      when(() => mockPlayer.absolutePosition()).thenReturn(1600000000000);
    });

    test('registerWith sets instance', () {
      BetterPlayerIOS.registerWith();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerIOS>());
    });

    test('buildView returns UiKitView widget', () {
      final widget = iosPlayer.buildView(1);
      expect(widget, isA<UiKitView>());
      final uiKitView = widget as UiKitView;
      expect(uiKitView.viewType, 'better_player_view');
      expect(uiKitView.creationParams, {'textureId': 1});
    });

    test('dispose calls native dispose', () async {
      await iosPlayer.create();

      await iosPlayer.dispose(1);

      verify(() => mockPlayer.dispose()).called(1);
    });

    test('create stores streams and returns textureId', () async {
      final textureId = await iosPlayer.create();
      expect(textureId, 1);
    });

    test(
      'play, pause, setVolume, setSpeed, setTrackParameters, setAudioTrack, setMixWithOthers, PiP interact with player',
      () async {
        await iosPlayer.create();

        await iosPlayer.play(1);
        verify(() => mockPlayer.play()).called(1);

        await iosPlayer.pause(1);
        verify(() => mockPlayer.pause()).called(1);

        await iosPlayer.setVolume(1, 0.5);
        verify(() => mockPlayer.setVolume(0.5)).called(1);

        await iosPlayer.setSpeed(1, 1.5);
        verify(() => mockPlayer.setSpeed(1.5)).called(1);

        await iosPlayer.setTrackParameters(1, 1920, 1080, 5000);
        verify(
          () =>
              mockPlayer.setTrackParameters(1920, height: 1080, bitrate: 5000),
        ).called(1);

        await iosPlayer.setAudioTrack(1, 'eng', 1);
        verify(() => mockPlayer.setAudioTrack('eng', index: 1)).called(1);

        await iosPlayer.setMixWithOthers(1, true);
        verify(() => mockPlayer.setMixWithOthers(true)).called(1);

        await iosPlayer.enablePictureInPicture(1, 0, 0, 100, 100);
        verify(() => mockPlayer.enablePictureInPicture(any())).called(1);

        await iosPlayer.disablePictureInPicture(1);
        verify(() => mockPlayer.disablePictureInPicture()).called(1);
      },
    );

    test('getAbsolutePosition returns correct value', () async {
      await iosPlayer.create();
      final absPos = await iosPlayer.getAbsolutePosition(1);
      expect(absPos, DateTime.fromMillisecondsSinceEpoch(1600000000000));
    });

    test('seekTo calls seekTo in ms', () async {
      await iosPlayer.create();
      await iosPlayer.seekTo(1, const Duration(seconds: 5));
      verify(() => mockPlayer.seekTo(5000)).called(1);
    });

    test('setLooping interacts with player', () async {
      await iosPlayer.create();
      await iosPlayer.setLooping(1, true);
      verify(() => mockPlayer.setLooping(true)).called(1);
    });

    test('getPosition returns correct value', () async {
      await iosPlayer.create();

      final pos = await iosPlayer.getPosition(1);
      expect(pos, const Duration(milliseconds: 5000));
    });

    test('videoEventsFor returns stream', () async {
      await iosPlayer.create();
      final stream = iosPlayer.videoEventsFor(1);
      expect(stream, isA<Stream<VideoEvent>>());
    });

    test('setDataSource handles DASH without throwing', () async {
      await iosPlayer.create();
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mpd',
      );

      // Verify it doesn't throw a synchronous exception
      expect(iosPlayer.setDataSource(1, dataSource), completes);
    });

    test(
      'setDataSource successfully delegates network URL to wrapper',
      () async {
        await iosPlayer.create();
        await iosPlayer.setDataSource(
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

    test('setDataSource successfully delegates Asset to wrapper', () async {
      await iosPlayer.create();
      await iosPlayer.setDataSource(
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
