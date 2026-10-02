import 'package:better_player_android/better_player_android.dart';
import 'package:better_player_android_surfaceview/better_player_android_surfaceview.dart';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWrapper extends Mock implements BetterPlayerWrapper {
  MockWrapper(this.id);
  final int id;
}

/// Replaces every JNI touch point, so `create()` runs without a device.
class TestSurfaceViewPlatform extends BetterPlayerAndroidSurfaceView {
  int _next = 1;
  final List<String> created = [];

  @override
  dynamic buildCallback(dynamic impl) => impl;

  @override
  BetterPlayerWrapper createWrapper(dynamic player) =>
      player as BetterPlayerWrapper;

  @override
  dynamic createSurfaceViewJniPlayer(dynamic callback) {
    created.add('surface');
    return MockWrapper(_next++);
  }

  @override
  dynamic createTextureJniPlayer(dynamic callback) {
    created.add('texture');
    return MockWrapper(_next++);
  }

  @override
  int readPlayerId(dynamic player) => (player as MockWrapper).id;
}

void main() {
  late TestSurfaceViewPlatform platform;

  setUp(() {
    platform = TestSurfaceViewPlatform();
    BetterPlayerAndroidSurfaceView.useSurfaceViewForNewPlayers = true;
  });

  test('registerWith installs the SurfaceView platform', () {
    BetterPlayerAndroidSurfaceView.registerWith();
    expect(
      BetterPlayerPlatform.instance,
      isA<BetterPlayerAndroidSurfaceView>(),
    );
  });

  test('players render through a SurfaceView by default', () async {
    final id = await platform.create();
    expect(platform.created, ['surface']);
    expect(platform.buildView(id), isA<SurfaceVideoView>());
  });

  test('flag off falls back to the Texture pipeline', () async {
    BetterPlayerAndroidSurfaceView.useSurfaceViewForNewPlayers = false;
    final id = await platform.create();
    expect(platform.created, ['texture']);
    expect(platform.buildView(id), isA<Texture>());
  });

  test('the choice is per player, not global', () async {
    final surfaceId = await platform.create();
    BetterPlayerAndroidSurfaceView.useSurfaceViewForNewPlayers = false;
    final textureId = await platform.create();
    expect(platform.buildView(surfaceId), isA<SurfaceVideoView>());
    expect(platform.buildView(textureId), isA<Texture>());
  });

  test(
    'dispose forgets the player so a reused id is not a SurfaceView',
    () async {
      final id = await platform.create();
      await platform.dispose(id);
      expect(platform.buildView(id), isA<Texture>());
    },
  );

  test('isSurfaceView reflects the registered platform instance', () async {
    BetterPlayerPlatform.instance = platform;
    final id = await platform.create();
    expect(BetterPlayerAndroidSurfaceView.isSurfaceView(id), isTrue);
    expect(BetterPlayerAndroidSurfaceView.isSurfaceView(null), isFalse);
    await platform.dispose(id);
    expect(BetterPlayerAndroidSurfaceView.isSurfaceView(id), isFalse);
  });
}
