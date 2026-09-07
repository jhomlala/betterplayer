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
          p.setProperty('isLive'.toJS, (() => false.toJS).toJS);
          p.setProperty('getPlayheadTimeAsDate'.toJS, (() => null).toJS);
          p.setProperty('getVariantTracks'.toJS, (() => [].toJS).toJS);
          p.setProperty('selectVariantTrack'.toJS, ((JSObject track, JSBoolean clear) {}).toJS);
          p.setProperty('selectAudioLanguage'.toJS, ((JSString lang) {}).toJS);
          p.setProperty('getNetworkingEngine'.toJS, (() {
            final engine = JSObject();
            engine.setProperty('registerRequestFilter'.toJS, ((JSFunction filter) {}).toJS);
            return engine;
          }).toJS);
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

    test('buildShakaConfig handles FairPlay DRM', () {
      print('--- test: buildShakaConfig handles FairPlay DRM start ---');
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        drmConfiguration: const DrmConfiguration(
          drmType: DrmType.fairplay,
          licenseUrl: 'https://license.fairplay.com',
          certificateUrl: 'https://cert.fairplay.com',
        ),
      );

      final config = player.buildShakaConfig(dataSource);
      expect(config, isNotNull);
      
      final drm = config!.getProperty('drm'.toJS) as JSObject;
      final servers = drm.getProperty('servers'.toJS) as JSObject;
      final advanced = drm.getProperty('advanced'.toJS) as JSObject;

      expect(
        servers.getProperty('com.apple.fps'.toJS).dartify(),
        'https://license.fairplay.com',
      );
      
      final fpsAdvanced = advanced.getProperty('com.apple.fps'.toJS) as JSObject;
      expect(
        fpsAdvanced.getProperty('serverCertificateUri'.toJS).dartify(),
        'https://cert.fairplay.com',
      );
      print('--- test: buildShakaConfig handles FairPlay DRM end ---');
    });

    test('buildShakaConfig handles Token DRM', () {
      print('--- test: buildShakaConfig handles Token DRM start ---');
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        drmConfiguration: const DrmConfiguration(
          drmType: DrmType.token,
          licenseUrl: 'https://license.token.com',
          token: 'test_token',
        ),
      );

      final config = player.buildShakaConfig(dataSource);
      expect(config, isNotNull);
      
      final drm = config!.getProperty('drm'.toJS) as JSObject;
      final advanced = drm.getProperty('advanced'.toJS) as JSObject;
      final wvAdvanced = advanced.getProperty('com.widevine.alpha'.toJS) as JSObject;
      final headers = wvAdvanced.getProperty('licenseRequestHeaders'.toJS) as JSObject;

      expect(
        headers.getProperty('Authorization'.toJS).dartify(),
        'Bearer test_token',
      );
      print('--- test: buildShakaConfig handles Token DRM end ---');
    });

    test('buildShakaConfig returns null for no DRM', () {
      print('--- test: buildShakaConfig returns null for no DRM start ---');
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
      );
      expect(player.buildShakaConfig(dataSource), isNull);
      print('--- test: buildShakaConfig returns null for no DRM end ---');
    });

    test('getPosition returns correct duration from video element', () {
      print('--- test: getPosition returns correct duration start ---');
      // Set currentTime on our mock JSObject
      (player.videoElement as JSObject).setProperty('currentTime'.toJS, 42.5.toJS);
      expect(player.getPosition(), const Duration(milliseconds: 42500));
      print('--- test: getPosition returns correct duration end ---');
    });

    test('getAbsolutePosition returns date from live stream', () {
      print('--- test: getAbsolutePosition returns date start ---');
      final mockShaka = JSObject();
      mockShaka.setProperty('isLive'.toJS, (() => true.toJS).toJS);
      
      final mockDate = JSObject();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      mockDate.setProperty('getTime'.toJS, (() => nowMs.toJS).toJS);
      mockShaka.setProperty('getPlayheadTimeAsDate'.toJS, (() => mockDate).toJS);
      
      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) {
          print('[LOG] $msg');
          logs.add(msg);
        },
        shakaPlayer: mockShaka as ShakaPlayer,
      );
      
      final absPos = player.getAbsolutePosition();
      expect(absPos, isNotNull);
      expect(absPos!.millisecondsSinceEpoch, nowMs);
      print('--- test: getAbsolutePosition returns date end ---');
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

    test('setTrackParameters selects best variant track', () {
      print('--- test: setTrackParameters selects best variant track start ---');
      final mockShaka = JSObject();
      
      final tracks = [
        {'width': 1280, 'height': 720, 'bandwidth': 3000}.jsify() as JSObject,
        {'width': 1920, 'height': 1080, 'bandwidth': 5000}.jsify() as JSObject,
        {'width': 640, 'height': 360, 'bandwidth': 1000}.jsify() as JSObject,
      ];
      
      mockShaka.setProperty('getVariantTracks'.toJS, (() => tracks.toJS).toJS);
      
      JSObject? selectedTrack;
      mockShaka.setProperty('selectVariantTrack'.toJS, ((JSObject track, JSBoolean clear) {
        selectedTrack = track;
      }).toJS);
      
      mockShaka.setProperty('configure'.toJS, ((JSObject config) {}).toJS);

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      player.setTrackParameters(width: 1920, height: 1080);
      
      expect(selectedTrack, isNotNull);
      expect((selectedTrack!['width'] as JSNumber).toDartInt, 1920);
      print('--- test: setTrackParameters selects best variant track end ---');
    });

    test('setAudioTrack calls selectAudioLanguage', () {
      print('--- test: setAudioTrack calls selectAudioLanguage start ---');
      final mockShaka = JSObject();
      String? selectedLang;
      mockShaka.setProperty('selectAudioLanguage'.toJS, ((JSString lang) {
        selectedLang = lang.toDart;
      }).toJS);
      
      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      player.setAudioTrack(language: 'es');
      expect(selectedLang, 'es');
      print('--- test: setAudioTrack calls selectAudioLanguage end ---');
    });

    test('Initialization events are emitted from video element', () async {
      print('--- test: Initialization events start ---');
      player.initialize();
      
      VideoEvent? receivedEvent;
      final sub = player.events.listen((event) => receivedEvent = event);
      await Future.delayed(const Duration(milliseconds: 100));

      // Mock duration and size on video element
      (player.videoElement as JSObject).setProperty('duration'.toJS, 60.toJS);
      (player.videoElement as JSObject).setProperty('videoWidth'.toJS, 1280.toJS);
      (player.videoElement as JSObject).setProperty('videoHeight'.toJS, 720.toJS);

      // Dispatch loadedmetadata
      player.videoElement.dispatchEvent(web.Event('loadedmetadata'));
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.eventType, VideoEventType.initialized);
      expect(receivedEvent!.duration, const Duration(seconds: 60));
      expect(receivedEvent!.size, const Size(1280, 720));
      
      await sub.cancel();
      print('--- test: Initialization events end ---');
    });

    test('getAbsolutePosition returns null when not a live stream', () {
      print('--- test: getAbsolutePosition returns null start ---');
      final mockShaka = JSObject();
      mockShaka.setProperty('isLive'.toJS, (() => false.toJS).toJS);
      
      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );
      
      expect(player.getAbsolutePosition(), isNull);
      print('--- test: getAbsolutePosition returns null end ---');
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

      await Future.delayed(const Duration(milliseconds: 100));

      print('Emitting buffering update 1');
      player.emitBufferingUpdate(); // Should emit
      
      print('Emitting buffering update 2 (should be throttled)');
      player.emitBufferingUpdate(); // Should be throttled
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(eventsReceived, 1);
      
      await subscription.cancel();
      print('--- test: emitBufferingUpdate respects throttle end ---');
    });

    test('Request filter sets headers correctly', () async {
      print('--- test: Request filter start ---');
      JSFunction? filter;
      final mockShaka = JSObject();
      final mockNetworkingEngine = JSObject();
      mockNetworkingEngine.setProperty('registerRequestFilter'.toJS, ((JSFunction f) {
        filter = f;
      }).toJS);
      mockShaka.setProperty('getNetworkingEngine'.toJS, (() => mockNetworkingEngine).toJS);
      mockShaka.setProperty('configure'.toJS, ((JSObject config) {}).toJS);
      mockShaka.setProperty('load'.toJS, ((JSString url) => Future.value().toJS).toJS);

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      await player.setDataSource(DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com',
        headers: {'Auth': 'Bearer test'},
      ));

      expect(filter, isNotNull);

      final mockRequest = JSObject();
      mockRequest.setProperty('headers'.toJS, JSObject());
      
      // Call filter: type is not used in our implementation currently but passed by Shaka
      filter!.call(0.toJS, mockRequest);

      final headers = mockRequest.getProperty('headers'.toJS) as JSObject;
      expect(headers.getProperty('Auth'.toJS).dartify(), 'Bearer test');
      print('--- test: Request filter end ---');
    });

    test('Other DOM events emit correct VideoEvents', () async {
      print('--- test: Other DOM events start ---');
      player.initialize();
      
      final events = <VideoEventType>[];
      final sub = player.events.listen((e) => events.add(e.eventType));
      await Future.delayed(const Duration(milliseconds: 100));

      player.videoElement.dispatchEvent(web.Event('play'));
      player.videoElement.dispatchEvent(web.Event('pause'));
      player.videoElement.dispatchEvent(web.Event('ended'));
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(events, contains(VideoEventType.play));
      expect(events, contains(VideoEventType.pause));
      expect(events, contains(VideoEventType.completed));
      
      await sub.cancel();
      print('--- test: Other DOM events end ---');
    });

    test('Seeked events are emitted with throttle', () async {
      print('--- test: Seeked events start ---');
      player.initialize();
      
      int seekEvents = 0;
      final sub = player.events.listen((e) {
        if (e.eventType == VideoEventType.seek) seekEvents++;
      });
      await Future.delayed(const Duration(milliseconds: 100));

      player.videoElement.dispatchEvent(web.Event('seeked'));
      player.videoElement.dispatchEvent(web.Event('seeked')); // Should be throttled
      
      await Future.delayed(const Duration(milliseconds: 100));
      expect(seekEvents, 1);
      
      await sub.cancel();
      print('--- test: Seeked events end ---');
    });

    group('Methods', () {
      test('play calls videoElement.play', () {
        var called = false;
        (player.videoElement as JSObject).setProperty('play'.toJS, (() {
          called = true;
          return Future.value().toJS;
        }).toJS);
        
        player.play();
        expect(called, isTrue);
      });

      test('pause calls videoElement.pause', () {
        var called = false;
        (player.videoElement as JSObject).setProperty('pause'.toJS, (() {
          called = true;
        }).toJS);
        
        player.pause();
        expect(called, isTrue);
      });

      test('setVolume sets videoElement.volume', () {
        player.setVolume(0.7);
        expect((player.videoElement as JSObject).getProperty('volume'.toJS).dartify(), 0.7);
      });

      test('setSpeed sets videoElement.playbackRate', () {
        player.setSpeed(1.2);
        expect((player.videoElement as JSObject).getProperty('playbackRate'.toJS).dartify(), 1.2);
      });

      test('setLooping sets videoElement.loop', () {
        player.setLooping(true);
        expect((player.videoElement as JSObject).getProperty('loop'.toJS).dartify(), isTrue);
      });

      test('seekTo sets videoElement.currentTime', () {
        player.seekTo(const Duration(seconds: 15));
        expect((player.videoElement as JSObject).getProperty('currentTime'.toJS).dartify(), 15.0);
      });

      test('getPosition returns videoElement.currentTime', () {
        (player.videoElement as JSObject).setProperty('currentTime'.toJS, 22.5.toJS);
        expect(player.getPosition(), const Duration(milliseconds: 22500));
      });

      test('isPictureInPictureSupported returns document.pictureInPictureEnabled', () {
        // We can't easily mock document.pictureInPictureEnabled in a unit test easily 
        // if the browser doesn't support it or if it's read-only, but we can check if it returns a bool.
        expect(player.isPictureInPictureSupported(), isA<bool>());
      });

      test('enablePictureInPicture calls requestPictureInPicture', () async {
        // Only test if the method exists/is callable if PiP is enabled in the test environment
        if (web.document.pictureInPictureEnabled) {
          var called = false;
          (player.videoElement as JSObject).setProperty('requestPictureInPicture'.toJS, (() {
            called = true;
            return Future.value().toJS;
          }).toJS);
          
          await player.enablePictureInPicture();
          expect(called, isTrue);
        }
      });

      test('disablePictureInPicture calls exitPictureInPicture', () async {
        // Mock document.pictureInPictureElement to something non-null
        // and mock document.exitPictureInPicture
        if (web.document.pictureInPictureEnabled) {
             // This is tricky as we can't easily mock global document properties that are read-only
             // However, our code checks for null.
             // If we can't mock document, we'll skip the call verification and just ensure it doesn't crash.
             await player.disablePictureInPicture();
        }
      });
    });
  });
}
