import 'dart:ffi' as ffi;
import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:better_player_windows/src/mpv/mpv_ffi.dart';
import 'package:better_player_windows/src/mpv/mpv_player.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ffi.Pointer<MpvEvent> noneEventPtr;
  late ffi.Pointer<MpvEvent> testEventPtr;
  late ffi.Pointer<MpvHandle> fakeHandle;
  final eventQueue = <void Function(ffi.Pointer<MpvEvent>)>[];
  final executedCommands = <List<String>>[];
  final propertyStrings = <String, String>{};
  final propertyDoubles = <String, double>{};
  final propertyInts = <String, int>{};
  final logs = <String>[];
  final createdPlayers = <MpvPlayer>[];
  var commandReturnCode = 0;

  MpvBindings createFakeBindings() {
    return MpvBindings.custom(
      mpvCreate: () => fakeHandle,
      mpvInitialize: (ctx) => 0,
      mpvDestroy: (ctx) {},
      mpvCommand: (ctx, argsPtr) {
        final cmd = <String>[];
        var i = 0;
        while (argsPtr[i] != ffi.nullptr) {
          cmd.add(argsPtr[i].toDartString());
          i++;
        }
        executedCommands.add(cmd);
        return commandReturnCode;
      },
      mpvCommandString: (ctx, str) => 0,
      mpvSetProperty: (ctx, namePtr, format, dataPtr) {
        final name = namePtr.toDartString();
        if (format == MpvFormat.doubleFormat && dataPtr != ffi.nullptr) {
          propertyDoubles[name] = dataPtr.cast<ffi.Double>().value;
        }
        return 0;
      },
      mpvSetPropertyString: (ctx, namePtr, valPtr) {
        propertyStrings[namePtr.toDartString()] = valPtr.toDartString();
        return 0;
      },
      mpvGetProperty: (ctx, namePtr, format, dataPtr) {
        final name = namePtr.toDartString();
        if (format == MpvFormat.int64 && dataPtr != ffi.nullptr) {
          dataPtr.cast<ffi.Int64>().value = propertyInts[name] ?? 0;
          return 0;
        }
        if (format == MpvFormat.doubleFormat && dataPtr != ffi.nullptr) {
          dataPtr.cast<ffi.Double>().value = propertyDoubles[name] ?? 0.0;
          return 0;
        }
        return 0;
      },
      mpvGetPropertyString: (ctx, namePtr) {
        final name = namePtr.toDartString();
        final val = propertyStrings[name];
        if (val != null) {
          return val.toNativeUtf8();
        }
        return ffi.nullptr;
      },
      mpvFree: (ptr) {
        if (ptr != ffi.nullptr) {
          calloc.free(ptr);
        }
      },
      mpvSetOptionString: (ctx, namePtr, valPtr) => 0,
      mpvObserveProperty: (ctx, reply, namePtr, format) => 0,
      mpvWaitEvent: (ctx, timeout) {
        if (eventQueue.isNotEmpty) {
          testEventPtr.ref.eventId = MpvEventId.none;
          testEventPtr.ref.error = 0;
          testEventPtr.ref.replyUserdata = 0;
          testEventPtr.ref.data = ffi.nullptr;
          final populate = eventQueue.removeAt(0);
          populate(testEventPtr);
          return testEventPtr;
        }
        noneEventPtr.ref.eventId = MpvEventId.none;
        noneEventPtr.ref.error = 0;
        noneEventPtr.ref.replyUserdata = 0;
        noneEventPtr.ref.data = ffi.nullptr;
        return noneEventPtr;
      },
      mpvErrorString: (err) => 'mpv error ($err)'.toNativeUtf8(),
      mpvRequestLogMessages: (ctx, minLevel) => 0,
    );
  }

  MpvPlayer createPlayer(
    MpvBindings bindings, {
    BufferingConfiguration? bufferingConfiguration,
    void Function({required String message, required int levelIndex})? onLog,
  }) {
    final player = MpvPlayer(
      textureId: 1,
      handle: fakeHandle,
      bufferingConfiguration: bufferingConfiguration,
      bindings: bindings,
      onLog: onLog,
    );
    createdPlayers.add(player);
    return player;
  }

  Future<VideoEvent> waitForEvent(
    MpvPlayer player,
    bool Function(VideoEvent) predicate, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    return player.events.firstWhere(predicate).timeout(timeout);
  }

  setUp(() {
    noneEventPtr = calloc<MpvEvent>()..ref.eventId = MpvEventId.none;
    testEventPtr = calloc<MpvEvent>();
    fakeHandle = ffi.Pointer<MpvHandle>.fromAddress(0x12345678);
    eventQueue.clear();
    executedCommands.clear();
    propertyStrings.clear();
    propertyDoubles.clear();
    propertyInts.clear();
    logs.clear();
    createdPlayers.clear();
    commandReturnCode = 0;
  });

  tearDown(() async {
    for (final player in createdPlayers) {
      await player.dispose();
    }
    createdPlayers.clear();
    calloc.free(noneEventPtr);
    calloc.free(testEventPtr);
  });

  group('MpvPlayer Tests', () {
    test(
      'setDataSource always sets http-header-fields even when empty',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(
          bindings,
          onLog: ({required message, required levelIndex}) => logs.add(message),
        );

        // 1. Set source with headers
        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video1.mp4',
            headers: {'Authorization': 'Bearer 123', 'Custom': 'Value'},
          ),
        );
        expect(
          propertyStrings['http-header-fields'],
          'Authorization: Bearer 123,Custom: Value',
        );

        // 2. Set source without headers -> should be reset to empty string
        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video2.mp4',
          ),
        );
        expect(propertyStrings['http-header-fields'], '');
        expect(propertyStrings['demuxer-max-bytes'], '150MiB');

        await player.dispose();
      },
    );

    test(
      'setDataSource throws PlatformException on loadfile command failure',
      () async {
        final bindings = createFakeBindings();
        commandReturnCode = -1; // simulate mpv error

        final player = createPlayer(bindings);

        expect(
          () => player.setDataSource(
            DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com/bad.mp4',
            ),
          ),
          throwsA(
            isA<PlatformException>().having(
              (e) => e.code,
              'code',
              'MPV_ERROR',
            ),
          ),
        );

        await player.dispose();
      },
    );

    test('seekTo throws PlatformException on seek command failure', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(bindings);

      commandReturnCode = -6; // simulate seek error
      expect(
        () => player.seekTo(const Duration(seconds: 10)),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'MPV_ERROR',
          ),
        ),
      );

      await player.dispose();
    });

    test(
      'setTrackParameters sets hls-bitrate without distorting video aspect ratio',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(
          bindings,
          onLog: ({required message, required levelIndex}) => logs.add(message),
        );

        await player.setTrackParameters(
          width: 1920,
          height: 1080,
          bitrate: 5000,
        );
        expect(propertyStrings.containsKey('video-aspect-override'), isFalse);
        expect(propertyStrings['hls-bitrate'], '5000');

        await player.setTrackParameters(width: 0, height: 0, bitrate: 0);
        expect(propertyStrings['hls-bitrate'], 'max');

        await player.dispose();
      },
    );

    test('setSpeed clamps to minimum 0.01 to prevent mpv error', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(bindings);

      await player.setSpeed(0);
      expect(propertyDoubles['speed'], 0.01);

      await player.setSpeed(2.5);
      expect(propertyDoubles['speed'], 2.5);

      await player.dispose();
    });

    test(
      'emits initialized on fileLoaded and changedSize on dimension update',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        final initFuture = waitForEvent(
          player,
          (e) => e.eventType == VideoEventType.initialized,
        );

        // 1. Simulate fileLoaded
        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.fileLoaded;
        });

        final initEvent = await initFuture;
        expect(initEvent.eventType, VideoEventType.initialized);

        // 2. Simulate dimension change property
        final nameUtf8 = 'width'.toNativeUtf8();
        final dataPtr = calloc<ffi.Int64>()..value = 1920;
        final prop = calloc<MpvEventProperty>()
          ..ref.name = nameUtf8
          ..ref.format = MpvFormat.int64
          ..ref.data = dataPtr.cast();

        final heightName = 'height'.toNativeUtf8();
        final heightData = calloc<ffi.Int64>()..value = 1080;
        final heightProp = calloc<MpvEventProperty>()
          ..ref.name = heightName
          ..ref.format = MpvFormat.int64
          ..ref.data = heightData.cast();

        final sizeFuture = waitForEvent(
          player,
          (e) =>
              e.eventType == VideoEventType.changedSize &&
              e.size == const Size(1920, 1080),
        );

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.propertyChange;
          ev.ref.data = prop.cast();
        });
        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.propertyChange;
          ev.ref.data = heightProp.cast();
        });

        final sizeEvent = await sizeFuture;
        expect(sizeEvent.size, const Size(1920, 1080));

        calloc.free(nameUtf8);
        calloc.free(dataPtr);
        calloc.free(prop);
        calloc.free(heightName);
        calloc.free(heightData);
        calloc.free(heightProp);
        await player.dispose();
      },
    );

    test(
      'deduplicates completed events between eof-reached and endFile',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        final receivedEvents = <VideoEvent>[];
        final sub = player.events.listen(receivedEvents.add);

        // 1. Simulate eof-reached propertyChange
        final eofName = 'eof-reached'.toNativeUtf8();
        final eofData = calloc<ffi.Int32>()..value = 1;
        final eofProp = calloc<MpvEventProperty>()
          ..ref.name = eofName
          ..ref.format = MpvFormat.flag
          ..ref.data = eofData.cast();

        // 2. Immediately simulate endFile event
        final endFile = calloc<MpvEventEndFile>()
          ..ref.reason = MpvEndFileReason.eof
          ..ref.error = 0;

        final completedFuture = waitForEvent(
          player,
          (e) => e.eventType == VideoEventType.completed,
        );

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.propertyChange;
          ev.ref.data = eofProp.cast();
        });
        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.endFile;
          ev.ref.error = 0;
          ev.ref.data = endFile.cast();
        });

        await completedFuture;
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final completedCount = receivedEvents
            .where((e) => e.eventType == VideoEventType.completed)
            .length;
        expect(completedCount, 1); // deduplicated!

        calloc.free(eofName);
        calloc.free(eofData);
        calloc.free(eofProp);
        calloc.free(endFile);
        await sub.cancel();
        await player.dispose();
      },
    );

    test('setDataSource normalizes file URIs for Windows paths', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(
        bindings,
        onLog: ({required message, required levelIndex}) => logs.add(message),
      );

      // 1. file:///C:/path/to/video.mp4 -> C:/path/to/video.mp4
      await player.setDataSource(
        DataSource(
          sourceType: DataSourceType.file,
          uri: 'file:///C:/path/to/video.mp4',
        ),
      );
      expect(executedCommands.last, ['loadfile', 'C:/path/to/video.mp4']);

      // 2. file://C:\path\to\video.mp4 -> C:\path\to\video.mp4
      await player.setDataSource(
        DataSource(
          sourceType: DataSourceType.file,
          uri: r'file://C:\path\to\video.mp4',
        ),
      );
      expect(executedCommands.last, ['loadfile', r'C:\path\to\video.mp4']);

      await player.dispose();
    });

    test(
      'setDataSource logs warning when DRM configuration is provided',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(
          bindings,
          onLog: ({required message, required levelIndex}) => logs.add(message),
        );

        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/video.mpd',
            drmConfiguration: const DrmConfiguration(
              drmType: DrmType.widevine,
              licenseUrl: 'https://license.example.com',
            ),
          ),
        );

        expect(
          logs.any(
            (l) => l.contains('DRM configuration is not supported on Windows'),
          ),
          isTrue,
        );

        await player.dispose();
      },
    );

    test('logs seeking state change on seeking property change', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(
        bindings,
        onLog: ({required message, required levelIndex}) => logs.add(message),
      );

      final seekingName = 'seeking'.toNativeUtf8();
      final seekingData = calloc<ffi.Int32>()..value = 1;
      final seekingProp = calloc<MpvEventProperty>()
        ..ref.name = seekingName
        ..ref.format = MpvFormat.flag
        ..ref.data = seekingData.cast();

      eventQueue.add((ptr) {
        ptr.ref.eventId = MpvEventId.propertyChange;
        ptr.ref.error = 0;
        ptr.ref.data = seekingProp.cast();
      });

      final stopwatch = Stopwatch()..start();
      while (!logs.any((l) => l.contains('SeekingState: SEEKING')) &&
          stopwatch.elapsedMilliseconds < 3000) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(logs.any((l) => l.contains('SeekingState: SEEKING')), isTrue);

      calloc.free(seekingName);
      calloc.free(seekingData);
      calloc.free(seekingProp);
      await player.dispose();
    });

    test('emits captionUpdate on sub-text property change', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(bindings);

      final subTextName = 'sub-text'.toNativeUtf8();
      final textString = 'First line\nSecond line'.toNativeUtf8();
      final strPtrPtr = calloc<ffi.Pointer<Utf8>>()..value = textString;
      final subTextProp = calloc<MpvEventProperty>()
        ..ref.name = subTextName
        ..ref.format = MpvFormat.string
        ..ref.data = strPtrPtr.cast();

      final captionFuture = waitForEvent(
        player,
        (e) => e.eventType == VideoEventType.captionUpdate,
      );

      eventQueue.add((ptr) {
        ptr.ref.eventId = MpvEventId.propertyChange;
        ptr.ref.error = 0;
        ptr.ref.data = subTextProp.cast();
      });

      final event = await captionFuture;
      expect(event.eventType, VideoEventType.captionUpdate);
      expect(event.captions, ['First line', 'Second line']);

      calloc.free(subTextName);
      calloc.free(textString);
      calloc.free(strPtrPtr);
      calloc.free(subTextProp);
      await player.dispose();
    });

    test('emits empty captionUpdate on sub-text nullptr', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(bindings);

      final subTextName = 'sub-text'.toNativeUtf8();
      final subTextProp = calloc<MpvEventProperty>()
        ..ref.name = subTextName
        ..ref.format = MpvFormat.none
        ..ref.data = ffi.nullptr;

      final captionFuture = waitForEvent(
        player,
        (e) => e.eventType == VideoEventType.captionUpdate,
      );

      eventQueue.add((ptr) {
        ptr.ref.eventId = MpvEventId.propertyChange;
        ptr.ref.error = 0;
        ptr.ref.data = subTextProp.cast();
      });

      final event = await captionFuture;
      expect(event.eventType, VideoEventType.captionUpdate);
      expect(event.captions, isEmpty);

      calloc.free(subTextName);
      calloc.free(subTextProp);
      await player.dispose();
    });

    test(
      'setTextTrack maps 0-based index to 1-based sid and handles disable',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        final events = <VideoEvent>[];
        final sub = player.events.listen(events.add);

        expect(propertyStrings['sub-visibility'], 'no');

        await player.setTextTrack(name: 'English', index: 0);
        expect(propertyStrings['sid'], '1');

        await player.setTextTrack(name: 'Spanish', index: 1);
        expect(propertyStrings['sid'], '2');

        await player.setTextTrack(name: 'English', index: -1);
        expect(propertyStrings['sid'], 'no');
        expect(events.last.eventType, VideoEventType.captionUpdate);
        expect(events.last.captions, isEmpty);

        await sub.cancel();
        await player.dispose();
      },
    );

    test(
      'setAudioTrack maps 0-based index to 1-based aid and handles disable',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        await player.setAudioTrack(name: 'English', index: 0);
        expect(propertyStrings['aid'], '1');

        await player.setAudioTrack(name: 'Spanish', index: 1);
        expect(propertyStrings['aid'], '2');

        await player.setAudioTrack(name: 'None', index: -1);
        expect(propertyStrings['aid'], 'no');

        await player.setAudioTrack(name: '', index: 0);
        expect(propertyStrings['aid'], 'no');

        await player.dispose();
      },
    );

    test('emits seek event on MpvEventId.seek', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(bindings);

      final seekFuture = waitForEvent(
        player,
        (e) => e.eventType == VideoEventType.seek,
      );

      eventQueue.add((ptr) {
        ptr.ref.eventId = MpvEventId.seek;
      });

      final event = await seekFuture;
      expect(event.eventType, VideoEventType.seek);

      await player.dispose();
    });

    test(
      'emits bufferingUpdate event on demuxer-cache-time propertyChange',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        final cacheName = 'demuxer-cache-time'.toNativeUtf8();
        final cacheData = calloc<ffi.Double>()..value = 5.5;
        final cacheProp = calloc<MpvEventProperty>()
          ..ref.name = cacheName
          ..ref.format = MpvFormat.doubleFormat
          ..ref.data = cacheData.cast();

        final bufferFuture = waitForEvent(
          player,
          (e) => e.eventType == VideoEventType.bufferingUpdate,
        );

        eventQueue.add((ptr) {
          ptr.ref.eventId = MpvEventId.propertyChange;
          ptr.ref.error = 0;
          ptr.ref.data = cacheProp.cast();
        });

        final event = await bufferFuture;
        expect(event.eventType, VideoEventType.bufferingUpdate);
        expect(event.buffered, isNotNull);
        expect(
          event.buffered!.first.end,
          const Duration(milliseconds: 5500),
        );

        calloc.free(cacheName);
        calloc.free(cacheData);
        calloc.free(cacheProp);
        await player.dispose();
      },
    );

    test(
      'methods after dispose are guarded and do not crash or invoke commands',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        await player.dispose();
        final cmdCountBefore = executedCommands.length;
        final propStringCountBefore = propertyStrings.length;

        // None of these should throw or invoke mpv
        await player.play();
        await player.pause();
        await player.setVolume(0.5);
        await player.setSpeed(1.5);
        await player.seekTo(const Duration(seconds: 5));
        await player.setLooping(looping: true);
        await player.setTrackParameters(
          width: 1280,
          height: 720,
          bitrate: 2000,
        );
        await player.setAudioTrack(name: 'English', index: 0);
        await player.setTextTrack(name: 'English', index: 0);
        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/test.mp4',
          ),
        );
        final pos = await player.getPosition();
        expect(pos, Duration.zero);

        expect(executedCommands.length, cmdCountBefore);
        expect(propertyStrings.length, propStringCountBefore);
      },
    );
    test('setDataSource configures ClearKey decryption_key on mpv', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(bindings);

      await player.setDataSource(
        DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/clearkey.mpd',
          drmConfiguration: const DrmConfiguration(
            drmType: DrmType.clearKey,
            clearKey: 'deadbeef12345678',
          ),
        ),
      );

      expect(
        propertyStrings['demuxer-lavf-o'],
        'decryption_key=deadbeef12345678',
      );
    });

    test('headers containing commas are quoted in http-header-fields', () async {
      final bindings = createFakeBindings();
      final player = createPlayer(bindings);

      await player.setDataSource(
        DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.com/test.mp4',
          headers: {
            'Accept': 'text/html,application/xhtml+xml',
            'User-Agent': 'Flutter,BetterPlayer',
          },
        ),
      );

      expect(
        propertyStrings['http-header-fields'],
        'Accept: "text/html,application/xhtml+xml",User-Agent: "Flutter,BetterPlayer"',
      );
    });

    test(
      'bufferingConfiguration sets demuxer-readahead-secs and demuxer-cache-wait',
      () async {
        final bindings = createFakeBindings();
        createPlayer(
          bindings,
          bufferingConfiguration: const BufferingConfiguration(
            minBufferMs: 2000,
            maxBufferMs: 30000,
          ),
        );

        expect(propertyDoubles['demuxer-readahead-secs'], 30.0);
        expect(propertyDoubles['demuxer-cache-wait'], 2.0);
      },
    );

    test(
      'overriddenDuration overrides raw duration on fileLoaded event',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        final eventFuture = waitForEvent(
          player,
          (e) =>
              e.eventType == VideoEventType.initialized &&
              e.duration == const Duration(seconds: 45),
        );

        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/test.mp4',
            overriddenDuration: const Duration(seconds: 45),
          ),
        );

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.fileLoaded;
        });

        final event = await eventFuture;
        expect(event.duration, const Duration(seconds: 45));
      },
    );

    test(
      'setTrackParameters sets vid when matching track is found in track-list',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        propertyInts['track-list/count'] = 2;
        propertyStrings['track-list/0/type'] = 'video';
        propertyInts['track-list/0/id'] = 1;
        propertyInts['track-list/0/demux-w'] = 1280;
        propertyInts['track-list/0/demux-h'] = 720;
        propertyInts['track-list/0/demux-bitrate'] = 2500000;

        propertyStrings['track-list/1/type'] = 'video';
        propertyInts['track-list/1/id'] = 2;
        propertyInts['track-list/1/demux-w'] = 1920;
        propertyInts['track-list/1/demux-h'] = 1080;
        propertyInts['track-list/1/demux-bitrate'] = 5000000;

        await player.setTrackParameters(
          width: 1920,
          height: 1080,
          bitrate: 5000000,
        );
        expect(propertyStrings['vid'], '2');

        await player.setTrackParameters(width: 0, height: 0, bitrate: 0);
        expect(propertyStrings['vid'], 'auto');
        expect(propertyStrings['hls-bitrate'], 'max');
      },
    );

    test(
      'MpvEventId.seek with position 0 emits seek event with Duration.zero',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        final eventFuture = waitForEvent(
          player,
          (e) => e.eventType == VideoEventType.seek,
        );

        propertyDoubles['time-pos'] = 0.0;
        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.seek;
        });

        final event = await eventFuture;
        expect(event.position, Duration.zero);
      },
    );
    test(
      'setAudioTrack resolves non-sequential track id from track-list',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        propertyInts['track-list/count'] = 3;
        propertyStrings['track-list/0/type'] = 'video';
        propertyInts['track-list/0/id'] = 1;

        propertyStrings['track-list/1/type'] = 'audio';
        propertyInts['track-list/1/id'] = 3;
        propertyStrings['track-list/1/lang'] = 'eng';
        propertyStrings['track-list/1/title'] = 'English';

        propertyStrings['track-list/2/type'] = 'audio';
        propertyInts['track-list/2/id'] = 5;
        propertyStrings['track-list/2/lang'] = 'spa';
        propertyStrings['track-list/2/title'] = 'Spanish';

        await player.setAudioTrack(name: 'Spanish', index: 1);
        expect(propertyStrings['aid'], '5');
      },
    );

    test(
      'setTextTrack resolves non-sequential track id from track-list',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        propertyInts['track-list/count'] = 2;
        propertyStrings['track-list/0/type'] = 'video';
        propertyInts['track-list/0/id'] = 1;

        propertyStrings['track-list/1/type'] = 'sub';
        propertyInts['track-list/1/id'] = 4;
        propertyStrings['track-list/1/lang'] = 'eng';
        propertyStrings['track-list/1/title'] = 'English';

        await player.setTextTrack(name: 'English', index: 0);
        expect(propertyStrings['sid'], '4');
      },
    );
    test(
      'setDataSource handles DataSourceType.asset and passes asset path to loadfile',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.asset,
            asset: 'assets/test_video.mp4',
          ),
        );

        expect(executedCommands.last.first, 'loadfile');
        expect(executedCommands.last.last.contains('test_video.mp4'), isTrue);
      },
    );

    test(
      'overriddenDuration overrides duration propertyChange event',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/test.mp4',
            overriddenDuration: const Duration(seconds: 45),
          ),
        );

        final durName = 'duration'.toNativeUtf8();
        final durData = calloc<ffi.Double>()..value = 120.0;
        final durProp = calloc<MpvEventProperty>()
          ..ref.name = durName
          ..ref.format = MpvFormat.doubleFormat
          ..ref.data = durData.cast();

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.propertyChange;
          ev.ref.data = durProp.cast();
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));

        calloc.free(durName);
        calloc.free(durData);
        calloc.free(durProp);
      },
    );

    test(
      'playbackRestart with position 0 updates currentPosition without crash',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        propertyDoubles['time-pos'] = 0.0;
        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.playbackRestart;
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final pos = await player.getPosition();
        expect(pos, Duration.zero);
      },
    );

    test(
      'endFile ignores audio initialization failure (-14)',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        final events = <VideoEvent>[];
        var hadError = false;
        final sub = player.events.listen(
          events.add,
          onError: (_) {
            hadError = true;
          },
        );

        final endFileData = calloc<MpvEventEndFile>()
          ..ref.error = -14
          ..ref.reason = MpvEndFileReason.error;

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.endFile;
          ev.ref.error = -14;
          ev.ref.data = endFileData.cast();
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(hadError, isFalse);

        calloc.free(endFileData);
        await sub.cancel();
      },
    );

    test(
      'ClearKey DRM resets demuxer-lavf-o when switching to a non-DRM stream',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        // 1. Set ClearKey stream
        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/drm.mpd',
            drmConfiguration: const DrmConfiguration(
              drmType: DrmType.clearKey,
              clearKey: 'key123',
            ),
          ),
        );
        expect(propertyStrings['demuxer-lavf-o'], 'decryption_key=key123');

        // 2. Set non-DRM stream -> resets to empty string
        await player.setDataSource(
          DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/clear.mp4',
          ),
        );
        expect(propertyStrings['demuxer-lavf-o'], '');
      },
    );

    test(
      'setAudioTrack matches by language code when index differs',
      () async {
        final bindings = createFakeBindings();
        final player = createPlayer(bindings);

        propertyInts['track-list/count'] = 2;
        propertyStrings['track-list/0/type'] = 'audio';
        propertyInts['track-list/0/id'] = 2;
        propertyStrings['track-list/0/lang'] = 'eng';
        propertyStrings['track-list/0/title'] = 'English';

        propertyStrings['track-list/1/type'] = 'audio';
        propertyInts['track-list/1/id'] = 7;
        propertyStrings['track-list/1/lang'] = 'fra';
        propertyStrings['track-list/1/title'] = 'French';

        await player.setAudioTrack(name: 'fra', index: 99);
        expect(propertyStrings['aid'], '7');
      },
    );
  });
}
