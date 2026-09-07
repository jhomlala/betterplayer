import 'dart:js_interop';

import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_web/src/better_player_web.dart';
import 'package:better_player_web/src/better_player_web_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web/web.dart' as web;

class MockBetterPlayerWebPlayer extends Mock implements BetterPlayerWebPlayer {}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('BetterPlayerWeb', () {
    late BetterPlayerWeb plugin;
    late MockBetterPlayerWebPlayer mockPlayer;

    setUp(() {
      mockPlayer = MockBetterPlayerWebPlayer();

      when(() => mockPlayer.initialize()).thenReturn(null);
      // Return a dummy JSObject cast to HTMLVideoElement to avoid DOM calls
      when(
        () => mockPlayer.videoElement,
      ).thenReturn(JSObject() as web.HTMLVideoElement);
      when(() => mockPlayer.viewId).thenReturn('test_view_id');

      plugin = BetterPlayerWeb(
        playerFactory: ({required viewId, required onLog}) => mockPlayer,
      );

      plugin.setupLogCallback(({required levelIndex, required message}) {});
    });

    test(
      'create assigns sequential texture IDs and initializes player',
      () async {
        final id1 = await plugin.create();
        final id2 = await plugin.create();

        expect(id1, 0);
        expect(id2, 1);
        verify(() => mockPlayer.initialize()).called(2);
      },
    );

    test('dispose calls player.dispose and removes from map', () async {
      when(() => mockPlayer.dispose()).thenAnswer((_) async {});

      final id = await plugin.create();
      await plugin.dispose(id);

      verify(() => mockPlayer.dispose()).called(1);
      expect(() => plugin.play(id), throwsStateError);
    });

    test('methods delegate to player correctly', () async {
      final id = await plugin.create();

      when(() => mockPlayer.play()).thenReturn(null);
      await plugin.play(id);
      verify(() => mockPlayer.play()).called(1);

      when(() => mockPlayer.pause()).thenReturn(null);
      await plugin.pause(id);
      verify(() => mockPlayer.pause()).called(1);

      when(() => mockPlayer.setVolume(any())).thenReturn(null);
      await plugin.setVolume(id, 0.5);
      verify(() => mockPlayer.setVolume(0.5)).called(1);

      when(() => mockPlayer.setSpeed(any())).thenReturn(null);
      await plugin.setSpeed(id, 1.5);
      verify(() => mockPlayer.setSpeed(1.5)).called(1);

      when(() => mockPlayer.setLooping(any())).thenReturn(null);
      await plugin.setLooping(id, true);
      verify(() => mockPlayer.setLooping(true)).called(1);

      when(() => mockPlayer.seekTo(any())).thenReturn(null);
      await plugin.seekTo(id, const Duration(seconds: 10));
      verify(() => mockPlayer.seekTo(const Duration(seconds: 10))).called(1);

      when(
        () => mockPlayer.getPosition(),
      ).thenReturn(const Duration(seconds: 5));
      final pos = await plugin.getPosition(id);
      expect(pos, const Duration(seconds: 5));

      when(() => mockPlayer.getAbsolutePosition()).thenReturn(DateTime(2023));
      final absPos = await plugin.getAbsolutePosition(id);
      expect(absPos, DateTime(2023));

      when(
        () => mockPlayer.setTrackParameters(
          width: any(named: 'width'),
          height: any(named: 'height'),
          bitrate: any(named: 'bitrate'),
        ),
      ).thenReturn(null);
      await plugin.setTrackParameters(id, 1920, 1080, 5000);
      verify(
        () => mockPlayer.setTrackParameters(
          width: 1920,
          height: 1080,
          bitrate: 5000,
        ),
      ).called(1);

      when(
        () => mockPlayer.setAudioTrack(
          language: any(named: 'language'),
          index: any(named: 'index'),
        ),
      ).thenReturn(null);
      await plugin.setAudioTrack(id, 'en', 1);
      verify(
        () => mockPlayer.setAudioTrack(language: 'en', index: 1),
      ).called(1);

      when(() => mockPlayer.enablePictureInPicture()).thenAnswer((_) async {});
      await plugin.enablePictureInPicture(id, null, null, null, null);
      verify(() => mockPlayer.enablePictureInPicture()).called(1);

      when(() => mockPlayer.disablePictureInPicture()).thenAnswer((_) async {});
      await plugin.disablePictureInPicture(id);
      verify(() => mockPlayer.disablePictureInPicture()).called(1);

      when(() => mockPlayer.isPictureInPictureSupported()).thenReturn(true);
      final pipSupported = await plugin.isPictureInPictureSupported(id);
      expect(pipSupported, true);
    });

    test('no-op methods log warnings', () async {
      int? lastLevel;
      String? lastMessage;
      await plugin.setupLogCallback(({required levelIndex, required message}) {
        lastLevel = levelIndex;
        lastMessage = message;
      });

      await plugin.preCache(
        DataSource(sourceType: DataSourceType.network, uri: 'url'),
        0,
      );
      expect(lastLevel, 2);
      expect(lastMessage, contains('preCache is not supported on web'));

      await plugin.stopPreCache('url', null);
      expect(lastLevel, 2);
      expect(lastMessage, contains('stopPreCache is not supported on web'));

      await plugin.clearCache();
      expect(lastLevel, 2);
      expect(lastMessage, contains('clearCache is not supported on web'));

      await plugin.setMixWithOthers(0, true);
      expect(lastLevel, 2);
      expect(lastMessage, contains('setMixWithOthers is not supported on web'));
    });

    test('seekTo with null position is a no-op', () async {
      final id = await plugin.create();
      await plugin.seekTo(id, null);
      verifyNever(() => mockPlayer.seekTo(any()));
    });

    test('setupLogCallback wires up callback and logs info', () async {
      int? lastLevel;
      String? lastMessage;
      await plugin.setupLogCallback(({
        required levelIndex,
        required String message,
      }) {
        lastLevel = levelIndex;
        lastMessage = message;
      });

      expect(lastLevel, 1);
      expect(lastMessage, contains('Log callback wired up for web'));
    });
  });
}
