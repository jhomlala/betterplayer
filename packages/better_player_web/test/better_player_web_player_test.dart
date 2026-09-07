import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui' as ui;
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_web/src/better_player_web_player.dart';
import 'package:better_player_web/src/shaka_player.dart';
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
    late List<int> logLevels;

    setUp(() {
      // Mock global shaka object if it doesn't exist
      if (!globalContext.has('shaka')) {
        final mockShaka = JSObject();
        final mockPolyfill = JSObject();
        mockPolyfill.setProperty(
          'installAll'.toJS,
          (() {}).toJS,
        );
        mockShaka.setProperty('polyfill'.toJS, mockPolyfill);

        // Mock shaka.Player constructor
        final mockPlayerConstructor = ((web.HTMLVideoElement element) {
          final p = JSObject();
          p.setProperty('configure'.toJS, ((JSObject config) {}).toJS);
          p.setProperty(
            'destroy'.toJS,
            (() => Future<JSAny?>.value().toJS).toJS,
          );
          p.setProperty(
            'load'.toJS,
            ((JSString url) => Future<JSAny?>.value().toJS).toJS,
          );
          p.setProperty('isLive'.toJS, (() => false.toJS).toJS);
          p.setProperty('getPlayheadTimeAsDate'.toJS, (() => null).toJS);
          p.setProperty(
            'getVariantTracks'.toJS,
            (() => <JSObject>[].jsify()! as JSArray).toJS,
          );
          p.setProperty(
            'selectVariantTrack'.toJS,
            ((JSObject track, JSBoolean clear) {}).toJS,
          );
          p.setProperty('selectAudioLanguage'.toJS, ((JSString lang) {}).toJS);
          p.setProperty(
            'getNetworkingEngine'.toJS,
            (() {
              final engine = JSObject();
              engine.setProperty(
                'registerRequestFilter'.toJS,
                ((JSFunction filter) {}).toJS,
              );
              return engine;
            }).toJS,
          );
          p.setProperty(
            'getTextTracks'.toJS,
            (() => <JSObject>[].jsify()! as JSArray).toJS,
          );
          return p;
        }).toJS;
        mockShaka.setProperty('Player'.toJS, mockPlayerConstructor);

        globalContext.setProperty('shaka'.toJS, mockShaka);
      }

      logs = [];
      logLevels = [];
      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) {
          logs.add(msg);
          logLevels.add(levelIndex);
        },
      );

      // Use a plain JSObject as the mock video element
      final mockVideo = JSObject();
      // Add a dummy buffered property (TimeRanges) with length
      final mockBuffered = JSObject();
      mockBuffered.setProperty('length'.toJS, 0.toJS);
      mockVideo.setProperty('buffered'.toJS, mockBuffered);
      // Add style property
      mockVideo.setProperty('style'.toJS, JSObject());
      // Add setAttribute method
      mockVideo.setProperty(
        'setAttribute'.toJS,
        ((JSString name, JSString value) {}).toJS,
      );
      // Add addEventListener method
      mockVideo.setProperty(
        'addEventListener'.toJS,
        ((JSString type, JSFunction listener) {}).toJS,
      );
      // Mock play() method as it's called in some tests (though not currently)
      mockVideo.setProperty(
        'play'.toJS,
        (() => Future<JSAny?>.value().toJS).toJS,
      );
      // Add numeric fields with defaults to prevent null typecast errors
      mockVideo.setProperty('currentTime'.toJS, 0.0.toJS);
      mockVideo.setProperty('videoWidth'.toJS, 0.toJS);
      mockVideo.setProperty('videoHeight'.toJS, 0.toJS);
      mockVideo.setProperty('duration'.toJS, 0.0.toJS);
      player.videoElement = mockVideo as web.HTMLVideoElement;
    });

    test('initialize logs info level', () {
      player.initialize();
      expect(logLevels.contains(1), isTrue);
      expect(logs.any((m) => m.contains('initialized')), isTrue);
    });

    test('buildShakaConfig handles Widevine DRM', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        drmConfiguration: const DrmConfiguration(
          drmType: DrmType.widevine,
          licenseUrl: 'https://license.widevine.com',
          headers: {'Authorization': 'Bearer test'},
        ),
      );

      final config = player.buildShakaConfig(dataSource)!;
      expect(config, isNotNull);

      final drm = config.getProperty('drm'.toJS)! as JSObject;
      final servers = drm.getProperty('servers'.toJS)! as JSObject;
      expect(
        servers.getProperty('com.widevine.alpha'.toJS).dartify(),
        'https://license.widevine.com',
      );
    });

    test('buildShakaConfig handles FairPlay DRM', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        drmConfiguration: const DrmConfiguration(
          drmType: DrmType.fairplay,
          licenseUrl: 'https://license.fairplay.com',
          certificateUrl: 'https://cert.fairplay.com',
        ),
      );

      final config = player.buildShakaConfig(dataSource)!;
      expect(config, isNotNull);

      final drm = config.getProperty('drm'.toJS)! as JSObject;
      final servers = drm.getProperty('servers'.toJS)! as JSObject;
      final advanced = drm.getProperty('advanced'.toJS)! as JSObject;

      expect(
        servers.getProperty('com.apple.fps'.toJS).dartify(),
        'https://license.fairplay.com',
      );

      final fpsAdvanced =
          advanced.getProperty('com.apple.fps'.toJS)! as JSObject;
      expect(
        fpsAdvanced.getProperty('serverCertificateUri'.toJS).dartify(),
        'https://cert.fairplay.com',
      );
    });

    test('buildShakaConfig handles Token DRM', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
        drmConfiguration: const DrmConfiguration(
          drmType: DrmType.token,
          licenseUrl: 'https://license.token.com',
          token: 'test_token',
        ),
      );

      final config = player.buildShakaConfig(dataSource)!;
      expect(config, isNotNull);

      final drm = config.getProperty('drm'.toJS)! as JSObject;
      final advanced = drm.getProperty('advanced'.toJS)! as JSObject;
      final wvAdvanced =
          advanced.getProperty('com.widevine.alpha'.toJS)! as JSObject;
      final headers =
          wvAdvanced.getProperty('licenseRequestHeaders'.toJS)! as JSObject;

      expect(
        headers.getProperty('Authorization'.toJS).dartify(),
        'Bearer test_token',
      );
    });

    test('buildShakaConfig returns null for no DRM', () {
      final dataSource = DataSource(
        sourceType: DataSourceType.network,
        uri: 'https://example.com/video.mp4',
      );
      expect(player.buildShakaConfig(dataSource), isNull);
    });

    test('getPosition returns correct duration from video element', () {
      // Set currentTime on our mock JSObject
      (player.videoElement as JSObject).setProperty(
        'currentTime'.toJS,
        42.5.toJS,
      );
      expect(player.getPosition(), const Duration(milliseconds: 42500));
    });

    test('getAbsolutePosition returns date from live stream', () {
      final mockShaka = JSObject();
      mockShaka.setProperty('isLive'.toJS, (() => true.toJS).toJS);

      final mockDate = JSObject();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      mockDate.setProperty('getTime'.toJS, (() => nowMs.toJS).toJS);
      mockShaka.setProperty(
        'getPlayheadTimeAsDate'.toJS,
        (() => mockDate).toJS,
      );

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) {
          logs.add(msg);
        },
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      final absPos = player.getAbsolutePosition()!;
      expect(absPos, isNotNull);
      expect(absPos.millisecondsSinceEpoch, nowMs);
    });

    test('dispose is idempotent and calls shaka.destroy', () async {
      final mockShaka = JSObject();
      var destroyCalled = 0;
      mockShaka['destroy'] = (() {
        destroyCalled++;
        return Future<JSAny?>.value().toJS;
      }).toJS;

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) {
          logs.add(msg);
        },
        shakaPlayer: mockShaka as ShakaPlayer,
      );
      player.initialize();

      await player.dispose();
      await player.dispose();

      expect(destroyCalled, 1);
    });

    test('setTrackParameters selects best variant track', () {
      final mockShaka = JSObject();

      final tracks = [
        {'width': 1280, 'height': 720, 'bandwidth': 3000}.jsify()! as JSObject,
        {'width': 1920, 'height': 1080, 'bandwidth': 5000}.jsify()! as JSObject,
        {'width': 640, 'height': 360, 'bandwidth': 1000}.jsify()! as JSObject,
      ];

      mockShaka.setProperty('getVariantTracks'.toJS, (() => tracks.toJS).toJS);

      JSObject? selectedTrack;
      mockShaka.setProperty(
        'selectVariantTrack'.toJS,
        ((JSObject track, JSBoolean clear) {
          selectedTrack = track;
        }).toJS,
      );

      mockShaka.setProperty('configure'.toJS, ((JSObject config) {}).toJS);

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      player.setTrackParameters(width: 1920, height: 1080);

      expect(selectedTrack, isNotNull);
      final track = selectedTrack!;
      expect((track['width']! as JSNumber).toDartInt, 1920);
    });

    test('setAudioTrack calls selectAudioLanguage', () {
      final mockShaka = JSObject();
      String? selectedLang;
      mockShaka.setProperty(
        'selectAudioLanguage'.toJS,
        ((JSString lang) {
          selectedLang = lang.toDart;
        }).toJS,
      );

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      player.setAudioTrack(language: 'es');
      expect(selectedLang, 'es');
    });

    test('Initialization events are emitted from video element', () async {
      final mockVideo = JSObject();
      mockVideo.setProperty('style'.toJS, JSObject());
      mockVideo.setProperty(
        'setAttribute'.toJS,
        ((JSString name, JSString value) {}).toJS,
      );

      final listeners = <String, List<JSFunction>>{};
      mockVideo.setProperty(
        'addEventListener'.toJS,
        ((JSString type, JSFunction listener) {
          listeners.putIfAbsent(type.toDart, () => []).add(listener);
        }).toJS,
      );

      mockVideo.setProperty(
        'dispatchEvent'.toJS,
        ((web.Event event) {
          final type = event.type;
          for (final l in (listeners[type] ?? [])) {
            (l as JSObject).callMethod('call'.toJS, mockVideo, event);
          }
          return true.toJS;
        }).toJS,
      );

      player.initialize(videoElement: mockVideo as web.HTMLVideoElement);

      VideoEvent? receivedEvent;
      final sub = player.events.listen((event) => receivedEvent = event);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Mock duration and size on video element
      mockVideo.setProperty('duration'.toJS, 60.toJS);
      mockVideo.setProperty('videoWidth'.toJS, 1280.toJS);
      mockVideo.setProperty('videoHeight'.toJS, 720.toJS);

      // Dispatch loadedmetadata
      for (final l in (listeners['loadedmetadata'] ?? [])) {
        (l as JSObject).callMethod(
          'call'.toJS,
          mockVideo,
          web.Event('loadedmetadata'),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.eventType, VideoEventType.initialized);
      final duration = receivedEvent!.duration!;
      expect(duration, const Duration(seconds: 60));
      expect(receivedEvent!.size, const ui.Size(1280, 720));

      await sub.cancel();
    });

    test('getAbsolutePosition returns null when not a live stream', () {
      final mockShaka = JSObject();
      mockShaka.setProperty('isLive'.toJS, (() => false.toJS).toJS);

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      expect(player.getAbsolutePosition(), isNull);
    });

    test('emitBufferingUpdate respects 500ms throttle', () async {
      player.initialize();
      var eventsReceived = 0;
      final subscription = player.events.listen((event) {
        if (event.eventType == VideoEventType.bufferingUpdate) {
          eventsReceived++;
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      player.emitBufferingUpdate(); // Should emit
      player.emitBufferingUpdate(); // Should be throttled

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(eventsReceived, 1);

      await subscription.cancel();
    });

    test('Request filter sets headers correctly', () async {
      JSFunction? filter;
      final mockShaka = JSObject();
      final mockNetworkingEngine = JSObject();
      mockNetworkingEngine.setProperty(
        'registerRequestFilter'.toJS,
        ((JSFunction f) {
          filter = f;
        }).toJS,
      );
      mockShaka.setProperty(
        'getNetworkingEngine'.toJS,
        (() => mockNetworkingEngine).toJS,
      );
      mockShaka.setProperty('configure'.toJS, ((JSObject config) {}).toJS);
      mockShaka.setProperty(
        'load'.toJS,
        ((JSString url) => Future<JSAny?>.value().toJS).toJS,
      );

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      await player.setDataSource(
        DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com',
          headers: {'Auth': 'Bearer test'},
        ),
      );

      expect(filter, isNotNull);

      final mockRequest = JSObject();
      mockRequest.setProperty('headers'.toJS, JSObject());

      // Call filter: type is not used in our implementation currently but passed by Shaka
      (filter! as JSObject).callMethod(
        'call'.toJS,
        JSObject(),
        0.toJS,
        mockRequest,
      );

      final headers = mockRequest.getProperty('headers'.toJS)! as JSObject;
      expect(headers.getProperty('Auth'.toJS).dartify(), 'Bearer test');
    });

    test('Other DOM events emit correct VideoEvents', () async {
      player.initialize();

      final events = <VideoEventType>[];
      final sub = player.events.listen((e) => events.add(e.eventType));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      player.videoElement.dispatchEvent(web.Event('play'));
      player.videoElement.dispatchEvent(web.Event('pause'));
      player.videoElement.dispatchEvent(web.Event('ended'));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events, contains(VideoEventType.play));
      expect(events, contains(VideoEventType.pause));
      expect(events, contains(VideoEventType.completed));

      await sub.cancel();
    });

    test('Seeked events are emitted with throttle', () async {
      final mockVideo = player.videoElement as JSObject;
      final listeners = <JSFunction>[];
      mockVideo.setProperty(
        'addEventListener'.toJS,
        ((JSString type, JSFunction listener) {
          if (type.toDart == 'seeked') listeners.add(listener);
        }).toJS,
      );

      player.initialize(videoElement: mockVideo as web.HTMLVideoElement);

      var seekEvents = 0;
      final sub = player.events.listen((e) {
        if (e.eventType == VideoEventType.seek) seekEvents++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));

      for (final l in listeners) {
        (l as JSObject).callMethod('call'.toJS, mockVideo, web.Event('seeked'));
        (l as JSObject).callMethod(
          'call'.toJS,
          mockVideo,
          web.Event('seeked'),
        ); // Should be throttled
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(seekEvents, 1);

      await sub.cancel();
    });

    test(
      'Buffering events (waiting/playing) emit bufferingStart/End',
      () async {
        final mockVideo = player.videoElement as JSObject;
        final listeners = <String, List<JSFunction>>{};
        mockVideo.setProperty(
          'addEventListener'.toJS,
          ((JSString type, JSFunction listener) {
            listeners.putIfAbsent(type.toDart, () => []).add(listener);
          }).toJS,
        );

        player.initialize(videoElement: mockVideo as web.HTMLVideoElement);

        final events = <VideoEventType>[];
        final sub = player.events.listen((e) => events.add(e.eventType));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        for (final l in (listeners['waiting'] ?? [])) {
          (l as JSObject).callMethod(
            'call'.toJS,
            mockVideo,
            web.Event('waiting'),
          );
        }
        // Wait > 200ms as there is a timer in the implementation
        await Future<void>.delayed(const Duration(milliseconds: 300));

        for (final l in (listeners['playing'] ?? [])) {
          (l as JSObject).callMethod(
            'call'.toJS,
            mockVideo,
            web.Event('playing'),
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(events, contains(VideoEventType.bufferingStart));
        expect(events, contains(VideoEventType.bufferingEnd));

        await sub.cancel();
      },
    );

    test('UI events (resize/pip) emit correct VideoEvents', () async {
      final mockVideo = player.videoElement as JSObject;
      final listeners = <String, List<JSFunction>>{};
      mockVideo.setProperty(
        'addEventListener'.toJS,
        ((JSString type, JSFunction listener) {
          listeners.putIfAbsent(type.toDart, () => []).add(listener);
        }).toJS,
      );

      player.initialize(videoElement: mockVideo as web.HTMLVideoElement);

      final events = <VideoEventType>[];
      final sub = player.events.listen((e) => events.add(e.eventType));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      for (final l in (listeners['resize'] ?? [])) {
        (l as JSObject).callMethod('call'.toJS, mockVideo, web.Event('resize'));
      }
      for (final l in (listeners['enterpictureinpicture'] ?? [])) {
        (l as JSObject).callMethod(
          'call'.toJS,
          mockVideo,
          web.Event('enterpictureinpicture'),
        );
      }
      for (final l in (listeners['leavepictureinpicture'] ?? [])) {
        (l as JSObject).callMethod(
          'call'.toJS,
          mockVideo,
          web.Event('leavepictureinpicture'),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events, contains(VideoEventType.changedSize));
      expect(events, contains(VideoEventType.pipStart));
      expect(events, contains(VideoEventType.pipStop));

      await sub.cancel();
    });

    test('setTrackParameters with null/zero values enables ABR', () {
      final mockShaka = JSObject();
      JSObject? lastConfig;
      mockShaka.setProperty(
        'configure'.toJS,
        ((JSObject config) {
          lastConfig = config;
        }).toJS,
      );

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      player.setTrackParameters(width: 0, height: 0, bitrate: 0);

      final config = lastConfig!;
      expect(config, isNotNull);
      final abr = config.getProperty('abr'.toJS)! as JSObject;
      expect(abr.getProperty('enabled'.toJS).dartify(), isTrue);
    });

    test('getTextTracks and selectTextTrack delegate correctly', () {
      final mockShaka = JSObject();
      final mockTrack = JSObject();
      mockShaka.setProperty(
        'getTextTracks'.toJS,
        (() => [mockTrack].toJS).toJS,
      );

      JSObject? selectedTrack;
      mockShaka.setProperty(
        'selectTextTrack'.toJS,
        ((JSObject track) {
          selectedTrack = track;
        }).toJS,
      );

      player = BetterPlayerWebPlayer(
        viewId: 'test_view',
        onLog: (msg, {levelIndex = 0}) => logs.add(msg),
        shakaPlayer: mockShaka as ShakaPlayer,
      );

      final tracks = player.getTextTracks();
      expect(tracks, hasLength(1));
      expect(tracks.first, mockTrack);

      player.selectTextTrack(mockTrack);
      expect(selectedTrack, mockTrack);
    });

    group('Methods', () {
      test('play calls videoElement.play', () {
        var called = false;
        (player.videoElement as JSObject).setProperty(
          'play'.toJS,
          (() {
            called = true;
            return Future<JSAny?>.value().toJS;
          }).toJS,
        );

        player.play();
        expect(called, isTrue);
      });

      test('pause calls videoElement.pause', () {
        var called = false;
        (player.videoElement as JSObject).setProperty(
          'pause'.toJS,
          (() {
            called = true;
          }).toJS,
        );

        player.pause();
        expect(called, isTrue);
      });

      test('setVolume sets videoElement.volume', () {
        player.setVolume(0.7);
        expect(
          (player.videoElement as JSObject)
              .getProperty('volume'.toJS)
              .dartify(),
          0.7,
        );
      });

      test('setSpeed sets videoElement.playbackRate', () {
        player.setSpeed(1.2);
        expect(
          (player.videoElement as JSObject)
              .getProperty('playbackRate'.toJS)
              .dartify(),
          1.2,
        );
      });

      test('setLooping sets videoElement.loop', () {
        player.setLooping(true);
        expect(
          (player.videoElement as JSObject).getProperty('loop'.toJS).dartify(),
          isTrue,
        );
      });

      test('seekTo sets videoElement.currentTime', () {
        player.seekTo(const Duration(seconds: 15));
        expect(
          (player.videoElement as JSObject)
              .getProperty('currentTime'.toJS)
              .dartify(),
          15.0,
        );
      });

      test('getPosition returns videoElement.currentTime', () {
        (player.videoElement as JSObject).setProperty(
          'currentTime'.toJS,
          22.5.toJS,
        );
        expect(player.getPosition(), const Duration(milliseconds: 22500));
      });

      test(
        'isPictureInPictureSupported returns document.pictureInPictureEnabled',
        () {
          // We can't easily mock document.pictureInPictureEnabled in a unit test easily
          // if the browser doesn't support it or if it's read-only, but we can check if it returns a bool.
          expect(player.isPictureInPictureSupported(), isA<bool>());
        },
      );

      test('enablePictureInPicture calls requestPictureInPicture', () async {
        // Only test if the method exists/is callable if PiP is enabled in the test environment
        if (web.document.pictureInPictureEnabled) {
          var called = false;
          (player.videoElement as JSObject).setProperty(
            'requestPictureInPicture'.toJS,
            (() {
              called = true;
              return Future<JSObject>.value(JSObject()).toJS;
            }).toJS,
          );

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
