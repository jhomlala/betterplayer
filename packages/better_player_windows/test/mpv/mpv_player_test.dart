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
  final logs = <String>[];
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
      mpvGetProperty: (ctx, namePtr, format, dataPtr) => 0,
      mpvGetPropertyString: (ctx, namePtr) => ffi.nullptr,
      mpvFree: (ptr) {},
      mpvSetOptionString: (ctx, namePtr, valPtr) => 0,
      mpvObserveProperty: (ctx, reply, namePtr, format) => 0,
      mpvWaitEvent: (ctx, timeout) {
        if (eventQueue.isNotEmpty) {
          final populate = eventQueue.removeAt(0);
          populate(testEventPtr);
          return testEventPtr;
        }
        noneEventPtr.ref.eventId = MpvEventId.none;
        return noneEventPtr;
      },
      mpvErrorString: (err) => 'mpv error ($err)'.toNativeUtf8(),
      mpvRequestLogMessages: (ctx, minLevel) => 0,
    );
  }

  setUp(() {
    noneEventPtr = calloc<MpvEvent>()..ref.eventId = MpvEventId.none;
    testEventPtr = calloc<MpvEvent>();
    fakeHandle = ffi.Pointer<MpvHandle>.fromAddress(0x12345678);
    eventQueue.clear();
    executedCommands.clear();
    propertyStrings.clear();
    propertyDoubles.clear();
    logs.clear();
    commandReturnCode = 0;
  });

  tearDown(() {
    calloc.free(noneEventPtr);
    calloc.free(testEventPtr);
  });

  group('MpvPlayer Tests', () {
    test(
      'setDataSource always sets http-header-fields even when empty',
      () async {
        final bindings = createFakeBindings();
        final player = MpvPlayer(
          textureId: 1,
          handle: fakeHandle,
          bindings: bindings,
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

        final player = MpvPlayer(
          textureId: 1,
          handle: fakeHandle,
          bindings: bindings,
        );

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
      final player = MpvPlayer(
        textureId: 1,
        handle: fakeHandle,
        bindings: bindings,
      );

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

    test('setTrackParameters does not distort video aspect ratio', () async {
      final bindings = createFakeBindings();
      final player = MpvPlayer(
        textureId: 1,
        handle: fakeHandle,
        bindings: bindings,
        onLog: ({required message, required levelIndex}) => logs.add(message),
      );

      await player.setTrackParameters(width: 1920, height: 1080, bitrate: 5000);
      expect(propertyStrings.containsKey('video-aspect-override'), isFalse);
      expect(
        logs.any(
          (l) => l.contains('track selection not supported on Windows yet'),
        ),
        isTrue,
      );

      await player.dispose();
    });

    test('setSpeed clamps to minimum 0.01 to prevent mpv error', () async {
      final bindings = createFakeBindings();
      final player = MpvPlayer(
        textureId: 1,
        handle: fakeHandle,
        bindings: bindings,
      );

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
        final player = MpvPlayer(
          textureId: 1,
          handle: fakeHandle,
          bindings: bindings,
        );

        final receivedEvents = <VideoEvent>[];
        final sub = player.events.listen(receivedEvents.add);

        // 1. Simulate fileLoaded
        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.fileLoaded;
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(receivedEvents.length, 1);
        expect(receivedEvents.first.eventType, VideoEventType.initialized);

        // 2. Simulate dimension change property
        final nameUtf8 = 'width'.toNativeUtf8();
        final dataPtr = calloc<ffi.Int64>()..value = 1920;
        final prop = calloc<MpvEventProperty>()
          ..ref.name = nameUtf8
          ..ref.format = MpvFormat.int64
          ..ref.data = dataPtr.cast();

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.propertyChange;
          ev.ref.data = prop.cast();
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Also set height
        final heightName = 'height'.toNativeUtf8();
        final heightData = calloc<ffi.Int64>()..value = 1080;
        final heightProp = calloc<MpvEventProperty>()
          ..ref.name = heightName
          ..ref.format = MpvFormat.int64
          ..ref.data = heightData.cast();

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.propertyChange;
          ev.ref.data = heightProp.cast();
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final initializedCount = receivedEvents
            .where((e) => e.eventType == VideoEventType.initialized)
            .length;
        expect(initializedCount, 1); // exactly one initialized event

        final changedSizeEvents = receivedEvents
            .where((e) => e.eventType == VideoEventType.changedSize)
            .toList();
        expect(changedSizeEvents, isNotEmpty);
        expect(changedSizeEvents.last.size, const Size(1920, 1080));

        calloc.free(nameUtf8);
        calloc.free(dataPtr);
        calloc.free(prop);
        calloc.free(heightName);
        calloc.free(heightData);
        calloc.free(heightProp);
        await sub.cancel();
        await player.dispose();
      },
    );

    test(
      'deduplicates completed events between eof-reached and endFile',
      () async {
        final bindings = createFakeBindings();
        final player = MpvPlayer(
          textureId: 1,
          handle: fakeHandle,
          bindings: bindings,
        );

        final receivedEvents = <VideoEvent>[];
        final sub = player.events.listen(receivedEvents.add);

        // 1. Simulate eof-reached propertyChange
        final eofName = 'eof-reached'.toNativeUtf8();
        final eofData = calloc<ffi.Int32>()..value = 1;
        final eofProp = calloc<MpvEventProperty>()
          ..ref.name = eofName
          ..ref.format = MpvFormat.flag
          ..ref.data = eofData.cast();

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.propertyChange;
          ev.ref.data = eofProp.cast();
        });

        // 2. Immediately simulate endFile event
        final endFile = calloc<MpvEventEndFile>()
          ..ref.reason = MpvEndFileReason.eof
          ..ref.error = 0;

        eventQueue.add((ev) {
          ev.ref.eventId = MpvEventId.endFile;
          ev.ref.error = 0;
          ev.ref.data = endFile.cast();
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));

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
  });
}
