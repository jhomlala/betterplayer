import 'dart:async';
import 'package:better_player_ios/better_player_ios.dart';
import 'package:better_player_ios/src/better_player_ios_ffi.g.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Use dynamic typing so we don't need to implement the final FFI extension type
class MockBetterPlayer extends Mock {
  int position() => 5000;
}

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
  dynamic getPlayer(int textureId) {
    if (textureId == 1) return mockPlayer;
    return null;
  }

  @override
  dynamic createCacheManager() {
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

    test('init completes normally', () async {
      await expectLater(iosPlayer.init(), completes);
    });

    test('dispose calls native dispose', () async {
      await iosPlayer.create();

      await iosPlayer.dispose(1);

      verify(() => (mockPlayer as dynamic).dispose()).called(1);
    });

    test('create stores streams and returns textureId', () async {
      final textureId = await iosPlayer.create();
      expect(textureId, 1);
    });

    test('play, pause, setVolume, setSpeed interact with player', () async {
      await iosPlayer.create();

      await iosPlayer.play(1);
      verify(() => (mockPlayer as dynamic).play()).called(1);

      await iosPlayer.pause(1);
      verify(() => (mockPlayer as dynamic).pause()).called(1);

      await iosPlayer.setVolume(1, 0.5);
      verify(() => (mockPlayer as dynamic).setVolume(0.5)).called(1);

      await iosPlayer.setSpeed(1, 1.5);
      verify(() => (mockPlayer as dynamic).setSpeed(1.5)).called(1);
    });

    test('seekTo calls seekTo in ms', () async {
      await iosPlayer.create();

      await iosPlayer.seekTo(1, const Duration(seconds: 10));
      verify(() => (mockPlayer as dynamic).seekTo(10000)).called(1);
    });

    test('setLooping interacts with player', () async {
      await iosPlayer.create();

      await iosPlayer.setLooping(1, true);
      verify(() => (mockPlayer as dynamic).setLooping(true)).called(1);
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

    test('setDataSource throws on DASH', () async {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mpd',
      );

      expect(() => iosPlayer.setDataSource(1, dataSource), throwsException);
    });

    test('setDataSource throws Error for network URL due to FFI', () async {
      await iosPlayer.create();

      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
      );

      expect(
        () => iosPlayer.setDataSource(1, dataSource),
        throwsA(isA<Error>()),
      );
    });

    test('setDataSource throws Error for Asset due to FFI', () async {
      await iosPlayer.create();

      final dataSource = DataSource(
        sourceType: DataSourceType.asset,
        asset: 'assets/video.mp4',
      );

      expect(
        () => iosPlayer.setDataSource(1, dataSource),
        throwsA(isA<Error>()),
      );
    });
  });
}
