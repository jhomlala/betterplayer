import 'dart:async';
import 'package:better_player_android/better_player_android.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBetterPlayer extends Mock implements BetterPlayerWrapper {
  int get textureId => 1;
  @override
  int get position => 5000;
  @override
  int get absolutePosition => 1600000000000;
}

class TestBetterPlayerAndroid extends BetterPlayerAndroid {
  final MockBetterPlayer mockPlayer;
  dynamic
  capturedCallback; // Now dynamic since we capture $BetterPlayerCallback

  TestBetterPlayerAndroid(this.mockPlayer);

  @override
  dynamic buildCallback(dynamic impl) {
    capturedCallback = impl;
    return impl; // Return raw object to bypass JNI
  }

  @override
  dynamic createJniPlayer(dynamic callback) {
    return mockPlayer;
  }

  @override
  BetterPlayerWrapper createWrapper(dynamic player) {
    return player as BetterPlayerWrapper;
  }
}

void main() {
  group('BetterPlayerAndroid tests', () {
    late MockBetterPlayer mockPlayer;
    late TestBetterPlayerAndroid androidPlayer;

    setUp(() {
      mockPlayer = MockBetterPlayer();
      androidPlayer = TestBetterPlayerAndroid(mockPlayer);
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

    test('init completes normally', () async {
      await expectLater(androidPlayer.init(), completes);
    });

    test('dispose calls native dispose and release', () async {
      await androidPlayer.create();
      await androidPlayer.dispose(1);
      verify(() => mockPlayer.dispose()).called(1);
      verify(() => mockPlayer.release()).called(1);
    });

    test('create stores player and returns textureId', () async {
      final textureId = await androidPlayer.create();
      expect(textureId, 1);
    });

    test('play, pause, setVolume, setSpeed interact with player', () async {
      await androidPlayer.create();

      await androidPlayer.play(1);
      verify(() => mockPlayer.play()).called(1);

      await androidPlayer.pause(1);
      verify(() => mockPlayer.pause()).called(1);

      await androidPlayer.setVolume(1, 0.5);
      verify(() => mockPlayer.volume = 0.5).called(1);

      await androidPlayer.setSpeed(1, 1.5);
      verify(() => mockPlayer.speed = 1.5).called(1);
    });

    test('seekTo calls seekTo in ms', () async {
      await androidPlayer.create();
      await androidPlayer.seekTo(1, const Duration(seconds: 5));
      verify(() => mockPlayer.seekTo(5000)).called(1);
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

    test('setDataSource throws Error due to JNI in test environment', () async {
      await androidPlayer.create();

      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
      );

      expect(
        () => androidPlayer.setDataSource(1, dataSource),
        throwsA(isA<Error>()),
      );
    });
  });
}
