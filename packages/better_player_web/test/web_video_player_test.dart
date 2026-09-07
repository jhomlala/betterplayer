import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_web/src/shaka_player.dart';
import 'package:better_player_web/src/web_video_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web/web.dart' as web;

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('BetterPlayerWebPlayer', () {
    late BetterPlayerWebPlayer player;
    late List<String> logs;

    setUp(() {
      print('--- setUp start ---');
      
      // Mock global shaka object if it doesn't exist
      if (!globalContext.has('shaka')) {
        print('[LOG] Mocking global shaka object');
        final mockShaka = JSObject();
        final mockPolyfill = JSObject();
        mockPolyfill.setProperty('installAll'.toJS, (() {
          print('[LOG] shaka.polyfill.installAll called');
        }).toJS);
        mockShaka.setProperty('polyfill'.toJS, mockPolyfill);
        
        // Mock shaka.Player constructor
        final mockPlayerConstructor = ((web.HTMLVideoElement element) {
          print('[LOG] shaka.Player constructor called');
          final p = JSObject();
          p.setProperty('configure'.toJS, ((JSObject config) {}).toJS);
          p.setProperty('destroy'.toJS, (() => Future.value().toJS).toJS);
          p.setProperty('load'.toJS, ((JSString url) => Future.value().toJS).toJS);
          return p;
        }).toJS;
        mockShaka.setProperty('Player'.toJS, mockPlayerConstructor);
        
        globalContext.setProperty('shaka'.toJS, mockShaka);
      }

      logs = [];
      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) {
          print('[LOG] $msg');
          logs.add(msg);
        },
      );
      
      // Use a plain JSObject as the mock video element
      print('[LOG] Creating mock video element');
      final mockVideo = JSObject();
      // Add a dummy buffered property (TimeRanges)
      mockVideo.setProperty('buffered'.toJS, JSObject());
      // Mock play() method as it's called in some tests (though not currently)
      mockVideo.setProperty('play'.toJS, (() => Future.value().toJS).toJS);
      player.videoElement = mockVideo as web.HTMLVideoElement;
      print('--- setUp end ---');
    });

    test('buildShakaConfig handles Widevine DRM', () {
      print('--- test: buildShakaConfig handles Widevine DRM start ---');
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        drmConfiguration: const DrmConfiguration(
          drmType: DrmType.widevine,
          licenseUrl: 'https://license.widevine.com',
          headers: {'Authorization': 'Bearer test'},
        ),
      );

      final config = player.buildShakaConfig(dataSource);
      expect(config, isNotNull);
      
      final drm = config!.getProperty('drm'.toJS) as JSObject;
      final servers = drm.getProperty('servers'.toJS) as JSObject;
      expect(
        servers.getProperty('com.widevine.alpha'.toJS).dartify(),
        'https://license.widevine.com',
      );
      print('--- test: buildShakaConfig handles Widevine DRM end ---');
    });

    test('getPosition returns correct duration from video element', () {
      print('--- test: getPosition returns correct duration start ---');
      // Set currentTime on our mock JSObject
      (player.videoElement as JSObject).setProperty('currentTime'.toJS, 42.5.toJS);
      expect(player.getPosition(), const Duration(milliseconds: 42500));
      print('--- test: getPosition returns correct duration end ---');
    });

    test('getAbsolutePosition returns null when not a live stream', () {
      print('--- test: getAbsolutePosition returns null start ---');
      final mockShaka = JSObject();
      mockShaka['isLive'] = (() => false.toJS).toJS;
      
      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) {
          print('[LOG] $msg');
          logs.add(msg);
        },
        shakaPlayer: mockShaka as ShakaPlayer,
      );
      
      expect(player.getAbsolutePosition(), isNull);
      print('--- test: getAbsolutePosition returns null end ---');
    });

    test('dispose is idempotent and calls shaka.destroy', () async {
      print('--- test: dispose is idempotent start ---');
      final mockShaka = JSObject();
      var destroyCalled = 0;
      mockShaka['destroy'] = (() {
        destroyCalled++;
        return Future.value().toJS;
      }).toJS;
      
      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) {
          print('[LOG] $msg');
          logs.add(msg);
        },
        shakaPlayer: mockShaka as ShakaPlayer,
      );
      print('Initializing player for dispose test');
      player.initialize(); 

      print('Calling dispose 1');
      await player.dispose();
      print('Calling dispose 2');
      await player.dispose();

      expect(destroyCalled, 1);
      print('--- test: dispose is idempotent end ---');
    });

    test('emitBufferingUpdate respects 500ms throttle', () async {
      print('--- test: emitBufferingUpdate respects throttle start ---');
      player.initialize();
      int eventsReceived = 0;
      final subscription = player.events.listen((event) {
        if (event.eventType == VideoEventType.bufferingUpdate) {
          eventsReceived++;
        }
      });

      // Give the broadcast stream a moment to settle
      await Future.delayed(const Duration(milliseconds: 100));

      print('Emitting buffering update 1');
      player.emitBufferingUpdate(); // Should emit
      
      print('Emitting buffering update 2 (should be throttled)');
      player.emitBufferingUpdate(); // Should be throttled
      
      // Wait for event delivery
      await Future.delayed(const Duration(milliseconds: 100));
      expect(eventsReceived, 1);
      
      await subscription.cancel();
      print('--- test: emitBufferingUpdate respects throttle end ---');
    });
  });
}
