import 'package:better_player_platform_interface/better_player_platform_interface.dart';
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

    test(
      'isPictureInPictureSupported calls isPictureInPictureSupported',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('better_player_channel'),
              (methodCall) async {
                log.add(methodCall);
                if (methodCall.method == 'isPictureInPictureSupported') {
                  return true;
                }
                return null;
              },
            );
        final supported = await player.isPictureInPictureSupported(1);
        expect(supported, true);
        expect(log.last.method, 'isPictureInPictureSupported');
        expect(log.last.arguments['textureId'], 1);
      },
    );

    group('setDataSource and preCache tests', () {
      test('setDataSource network source correctly maps data', () async {
        final dataSource = DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/video.mp4',
          headers: {'Authorization': 'Bearer token'},
          useCache: true,
          maxCacheSize: 1000,
          maxCacheFileSize: 100,
        );

        await player.setDataSource(1, dataSource);

        expect(log.length, 1);
        expect(log[0].method, 'setDataSource');
        final args = log[0].arguments;
        expect(args['textureId'], 1);
        final dsMap = args['dataSource'];
        expect(dsMap['uri'], 'https://example.com/video.mp4');
        expect(dsMap['headers'], {'Authorization': 'Bearer token'});
        expect(dsMap['useCache'], true);
        expect(dsMap['maxCacheSize'], 1000);
      });

      test('setDataSource asset source correctly maps data', () async {
        final dataSource = DataSource(
          sourceType: DataSourceType.asset,
          asset: 'assets/video.mp4',
          package: 'my_package',
        );

        await player.setDataSource(1, dataSource);

        final dsMap = log[0].arguments['dataSource'];
        expect(dsMap['asset'], 'assets/video.mp4');
        expect(dsMap['package'], 'my_package');
        expect(dsMap['useCache'], false);
      });

      test('preCache correctly adds preCacheSize', () async {
        final dataSource = DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/video.mp4',
        );

        await player.preCache(dataSource, 5000);

        expect(log.length, 1);
        expect(log[0].method, 'preCache');
        final dsMap = log[0].arguments['dataSource'];
        expect(dsMap['uri'], 'https://example.com/video.mp4');
        expect(dsMap['preCacheSize'], 5000);
      });
    });
  });
}
