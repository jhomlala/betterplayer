import 'dart:async';
import 'package:better_player_android/better_player_android.dart';
import 'package:better_player_android/src/better_player_android_jni.g.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBetterPlayer extends Mock implements BetterPlayerWrapper {
  final int textureId;
  MockBetterPlayer(this.textureId);
}

class TestBetterPlayerAndroid extends BetterPlayerAndroid {
  int _nextTextureId = 1;
  final List<dynamic> capturedCallbacks = [];

  @override
  dynamic buildCallback(dynamic impl) {
    capturedCallbacks.add(impl);
    return impl; // Return raw object to bypass JNI
  }

  MockBetterPlayer get mockPlayer => _createdMocks.first;
  final List<MockBetterPlayer> _createdMocks = [];

  @override
  dynamic createJniPlayer(dynamic callback) {
    final mock = MockBetterPlayer(_nextTextureId++);
    when(() => mock.position).thenReturn(5000);
    when(() => mock.absolutePosition).thenReturn(1600000000000);
    _createdMocks.add(mock);
    return mock;
  }

  @override
  BetterPlayerWrapper createWrapper(dynamic player) {
    return player as BetterPlayerWrapper;
  }

  @override
  int getTextureIdFromPlayer(dynamic player) {
    return (player as MockBetterPlayer).textureId;
  }

  @override
  void jniPreCache(
    String dataSource,
    int preCacheSize,
    int maxCacheSize,
    int maxCacheFileSize,
    Map<String, String?>? headers,
    String? cacheKey,
  ) {}

  @override
  void jniStopPreCache(String url) {}

  @override
  void jniClearCache() {}
}

void main() {
  group('BetterPlayerAndroid tests', () {
    late TestBetterPlayerAndroid androidPlayer;

    setUp(() {
      androidPlayer = TestBetterPlayerAndroid();
    });

    test('registerWith sets instance', () {
      BetterPlayerAndroid.registerWith();
      expect(BetterPlayerPlatform.instance, isA<BetterPlayerAndroid>());
    });

    test('buildView returns Texture widget', () {
      final widget = androidPlayer.buildView(1);
      expect(widget, isA<Texture>());
      expect((widget as Texture).textureId, 1);
    });

    test('dispose calls native dispose and release', () async {
      await androidPlayer.create();
      await androidPlayer.dispose(1);
      verify(() => androidPlayer.mockPlayer.dispose()).called(1);
      verify(() => androidPlayer.mockPlayer.release()).called(1);
    });

    test('create stores player and returns textureId', () async {
      final textureId = await androidPlayer.create();
      expect(textureId, 1);
    });

    test(
      'play, pause, setVolume, setSpeed, setTrackParameters, setAudioTrack, setMixWithOthers interact with player',
      () async {
        await androidPlayer.create();

        await androidPlayer.play(1);
        verify(() => androidPlayer.mockPlayer.play()).called(1);

        await androidPlayer.pause(1);
        verify(() => androidPlayer.mockPlayer.pause()).called(1);

        await androidPlayer.setVolume(1, 0.5);
        verify(() => androidPlayer.mockPlayer.volume = 0.5).called(1);

        await androidPlayer.setSpeed(1, 1.5);
        verify(() => androidPlayer.mockPlayer.speed = 1.5).called(1);

        await androidPlayer.setTrackParameters(1, 1920, 1080, 5000);
        verify(
          () => androidPlayer.mockPlayer.setTrackParameters(1920, 1080, 5000),
        ).called(1);

        await androidPlayer.setLooping(1, true);
        verify(() => androidPlayer.mockPlayer.looping = true).called(1);

        await androidPlayer.setAudioTrack(1, 'eng', 1);
        verify(
          () => androidPlayer.mockPlayer.setAudioTrack(any(), 1),
        ).called(1);

        await androidPlayer.setMixWithOthers(1, true);
        verify(() => androidPlayer.mockPlayer.mixWithOthers = true).called(1);

        await androidPlayer.setAndroidMatchFrameRate(1, true);
        verify(
          () => androidPlayer.mockPlayer.setMatchFrameRate(true),
        ).called(1);
      },
    );

    test('seekTo calls seekTo in ms', () async {
      await androidPlayer.create();
      await androidPlayer.seekTo(1, const Duration(seconds: 5));
      verify(() => androidPlayer.mockPlayer.seekTo(5000)).called(1);
    });

    test('getPosition and getAbsolutePosition return correct values', () async {
      await androidPlayer.create();
      final pos = await androidPlayer.getPosition(1);
      final absPos = await androidPlayer.getAbsolutePosition(1);

      expect(pos, const Duration(milliseconds: 5000));
      expect(absPos, DateTime.fromMillisecondsSinceEpoch(1600000000000));
    });

    test('videoEventsFor returns stream', () async {
      await androidPlayer.create();
      final stream = androidPlayer.videoEventsFor(1);
      expect(stream, isA<Stream<VideoEvent>>());
    });

    test('setDataSource successfully delegates to wrapper', () async {
      await androidPlayer.create();

      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        drmConfiguration: const DrmConfiguration(
          drmType: DrmType.widevine,
          licenseUrl: 'https://license.com',
          drmSecurityLevel: DrmSecurityLevel.l1,
        ),
      );

      await androidPlayer.setDataSource(1, dataSource);
      verify(
        () => androidPlayer.mockPlayer.setDataSource(
          any(),
          'https://example.com/video.mp4',
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          'L1',
        ),
      ).called(1);
    });

    test(
      'setDataSource throws UnsupportedError for Web-specific DrmSecurityLevel',
      () async {
        await androidPlayer.create();

        final dataSource = DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/video.mp4',
          drmConfiguration: const DrmConfiguration(
            drmType: DrmType.widevine,
            licenseUrl: 'https://license.com',
            drmSecurityLevel: DrmSecurityLevel.hwSecureAll,
          ),
        );

        expect(
          () => androidPlayer.setDataSource(1, dataSource),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

    test(
      'setDataSource with file source delegates to wrapper with file:// URI',
      () async {
        await androidPlayer.create();

        final dataSource = DataSource(
          sourceType: DataSourceType.file,
          uri: 'file:///path/to/video.mp4',
        );

        await androidPlayer.setDataSource(1, dataSource);
        verify(
          () => androidPlayer.mockPlayer.setDataSource(
            any(),
            'file:///path/to/video.mp4',
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).called(1);
      },
    );

    test(
      'preCache, stopPreCache, clearCache complete normally in test',
      () async {
        final dataSource = DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/video.mp4',
        );
        await expectLater(androidPlayer.preCache(dataSource, 100), completes);
        await expectLater(androidPlayer.stopPreCache('url', null), completes);
        await expectLater(androidPlayer.clearCache(), completes);
      },
    );
    test('videoEventsFor does not leak events to other players', () async {
      final texture1 = await androidPlayer.create();
      final texture2 = await androidPlayer.create();

      final stream1 = androidPlayer.videoEventsFor(texture1);
      final stream2 = androidPlayer.videoEventsFor(texture2);

      final events1 = <VideoEvent>[];
      final events2 = <VideoEvent>[];

      final sub1 = stream1.listen(events1.add);
      final sub2 = stream2.listen(events2.add);

      // Extract the captured JNI callbacks
      final callback1 =
          androidPlayer.capturedCallbacks[0] as $BetterPlayerCallback;
      final callback2 =
          androidPlayer.capturedCallbacks[1] as $BetterPlayerCallback;

      // Fire an event on player 2's callback
      callback2.onPlay();

      // Wait a tick for streams to propagate
      await Future<void>.delayed(Duration.zero);

      expect(events2, hasLength(1));
      expect(events2.first.eventType, VideoEventType.play);
      expect(
        events1,
        isEmpty,
        reason: 'Player 1 should not receive player 2 events',
      );

      await sub1.cancel();
      await sub2.cancel();
    });
  });
}
