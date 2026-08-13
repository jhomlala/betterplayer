import 'package:better_player/src/video_player/method_channel_video_player.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelVideoPlayer tests', () {
    final player = MethodChannelVideoPlayer();
    final log = <MethodCall>[];

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_channel'),
            (methodCall) async {
              log.add(methodCall);
              if (methodCall.method == 'create') {
                return {'textureId': 1};
              }
              return null;
            },
          );
      log.clear();
    });

    test('init calls init', () async {
      await player.init();
      expect(log.length, 1);
      expect(log[0].method, 'init');
    });

    test('create calls create', () async {
      final textureId = await player.create();
      expect(textureId, 1);
      expect(log.length, 1);
      expect(log[0].method, 'create');
    });

    test('dispose calls dispose', () async {
      await player.dispose(1);
      expect(log.length, 1);
      expect(log[0].method, 'dispose');
      expect(log[0].arguments, {'textureId': 1});
    });

    test('play calls play', () async {
      await player.play(1);
      expect(log.length, 1);
      expect(log[0].method, 'play');
    });

    test('pause calls pause', () async {
      await player.pause(1);
      expect(log.length, 1);
      expect(log[0].method, 'pause');
    });

    test('setLooping calls setLooping', () async {
      await player.setLooping(1, true);
      expect(log.length, 1);
      expect(log[0].method, 'setLooping');
      expect(log[0].arguments['looping'], true);
    });

    test('setVolume calls setVolume', () async {
      await player.setVolume(1, 0.5);
      expect(log.length, 1);
      expect(log[0].method, 'setVolume');
      expect(log[0].arguments['volume'], 0.5);
    });

    test('setSpeed calls setSpeed', () async {
      await player.setSpeed(1, 1.5);
      expect(log.length, 1);
      expect(log[0].method, 'setSpeed');
      expect(log[0].arguments['speed'], 1.5);
    });

    test('setTrackParameters calls setTrackParameters', () async {
      await player.setTrackParameters(1, 1920, 1080, 5000);
      expect(log.length, 1);
      expect(log[0].method, 'setTrackParameters');
      expect(log[0].arguments['width'], 1920);
    });

    test('seekTo calls seekTo', () async {
      await player.seekTo(1, const Duration(seconds: 10));
      expect(log.length, 1);
      expect(log[0].method, 'seekTo');
      expect(log[0].arguments['location'], 10000);
    });

    test('getPosition calls getPosition', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('better_player_channel'),
            (methodCall) async {
              if (methodCall.method == 'position') {
                return 5000;
              }
              return null;
            },
          );
      final pos = await player.getPosition(1);
      expect(pos.inSeconds, 5);
    });
  });
}
