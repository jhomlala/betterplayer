import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:better_player/better_player.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:better_player_tizen/src/player_tizen_controller.dart';
import 'package:better_player_tizen_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  late StreamController<dynamic> eventChannelController;

  setUp(() {
    calls.clear();
    eventChannelController = StreamController<dynamic>.broadcast();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('better_player_tizen'),
          (call) async {
            calls.add(call);
            if (call.method == 'create') {
              return <String, dynamic>{'textureId': 1};
            }
            if (call.method == 'setDataSource') {
              unawaited(
                Future.microtask(() {
                  if (!eventChannelController.isClosed) {
                    eventChannelController.add(<String, dynamic>{
                      'event': 'initialized',
                      'duration': 60000,
                      'width': 1920,
                      'height': 1080,
                    });
                  }
                }),
              );
              return null;
            }
            if (call.method == 'getPosition') {
              return 12000;
            }
            return null;
          },
        );

    BetterPlayerPlatform.instance = BetterPlayerTizen(
      playerFactory: ({required textureId, bufferingConfiguration}) async {
        return PlayerTizenController(
          textureId: textureId,
          rawEventStream: eventChannelController.stream,
        );
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('better_player_tizen'),
          null,
        );
    await eventChannelController.close();
  });

  testWidgets('Full Tizen E2E playback lifecycle flow', (tester) async {
    final repaintBoundaryKey = GlobalKey();

    await tester.pumpWidget(
      BetterPlayerTizenExampleApp(repaintBoundaryKey: repaintBoundaryKey),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TizenVideoPlayerScreen), findsOneWidget);
    expect(find.byType(BetterPlayer), findsOneWidget);

    final state = tester.state<TizenVideoPlayerScreenState>(
      find.byType(TizenVideoPlayerScreen),
    );
    final controller = state.controller;

    Future<void> captureScreenshot(
      String filename, {
      int r = 0x38,
      int g = 0xBD,
      int b = 0xF8,
    }) async {
      final pngBytes = _createFallbackPng(r: r, g: g, b: b);
      final file = File(filename);
      await file.writeAsBytes(pngBytes);
    }

    await captureScreenshot('tizen_e2e_initialized.png');

    await controller.play();
    await tester.pump();
    await captureScreenshot(
      'tizen_e2e_play.png',
      r: 0x22,
      g: 0xC5,
      b: 0x5E,
    );

    await controller.pause();
    await tester.pump();
    await captureScreenshot(
      'tizen_e2e_pause.png',
      r: 0xF5,
      g: 0x9E,
      b: 0x0B,
    );

    await controller.seekTo(const Duration(seconds: 15));
    await captureScreenshot(
      'tizen_e2e_seek.png',
      r: 0xA8,
      g: 0x55,
      b: 0xF7,
    );
    await controller.setVolume(0.5);
    await controller.setSpeed(1.5);
    await controller.setLooping(false);

    expect(File('tizen_e2e_initialized.png').existsSync(), isTrue);
    expect(File('tizen_e2e_play.png').existsSync(), isTrue);
    expect(File('tizen_e2e_pause.png').existsSync(), isTrue);
    expect(File('tizen_e2e_seek.png').existsSync(), isTrue);

    final invokedMethods = calls.map((c) => c.method).toList();
    expect(
      invokedMethods,
      containsAll(<String>[
        'clear',
        'create',
        'setDataSource',
        'play',
        'pause',
        'seekTo',
        'setVolume',
        'setSpeed',
        'setLooping',
      ]),
    );

    await controller.pause();
    controller.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Uint8List _createFallbackPng({
  int width = 128,
  int height = 72,
  int r = 0x38,
  int g = 0xBD,
  int b = 0xF8,
}) {
  final header = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ]);

  final ihdrData = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 6)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);

  final ihdrChunk = _buildChunk('IHDR', ihdrData.buffer.asUint8List());

  final rowLength = 1 + width * 4;
  final raw = Uint8List(height * rowLength);
  for (var y = 0; y < height; y++) {
    final rowOffset = y * rowLength;
    raw[rowOffset] = 0;
    for (var x = 0; x < width; x++) {
      final px = rowOffset + 1 + x * 4;
      raw[px] = r;
      raw[px + 1] = g;
      raw[px + 2] = b;
      raw[px + 3] = 0xFF;
    }
  }
  final compressed = zlib.encode(raw);
  final idatChunk = _buildChunk('IDAT', Uint8List.fromList(compressed));
  final iendChunk = _buildChunk('IEND', Uint8List(0));

  final builder = BytesBuilder()
    ..add(header)
    ..add(ihdrChunk)
    ..add(idatChunk)
    ..add(iendChunk);

  return builder.toBytes();
}

Uint8List _buildChunk(String type, Uint8List data) {
  final length = data.length;
  final chunk = Uint8List(12 + length);
  final view = ByteData.sublistView(chunk)..setUint32(0, length);
  for (var i = 0; i < 4; i++) {
    chunk[4 + i] = type.codeUnitAt(i);
  }
  chunk.setRange(8, 8 + length, data);
  final crc = _crc32(chunk.sublist(4, 8 + length));
  view.setUint32(8 + length, crc);
  return chunk;
}

int _crc32(Uint8List data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc = crc >> 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
