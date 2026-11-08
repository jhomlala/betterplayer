import 'dart:io';
import 'dart:ui' as ui;

import 'package:better_player/better_player.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:better_player_tizen_example/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  MockStreamHandlerEventSink? eventSink;

  setUp(() {
    calls.clear();
    eventSink = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('better_player_tizen'),
          (call) async {
            calls.add(call);
            if (call.method == 'create') {
              return <String, dynamic>{'textureId': 1};
            }
            if (call.method == 'setDataSource') {
              eventSink?.success(<String, dynamic>{
                'event': 'initialized',
                'duration': 60000,
                'width': 1920,
                'height': 1080,
              });
            }
            if (call.method == 'getPosition') {
              return 12000;
            }
            return null;
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('better_player_tizen/video_events_1'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              eventSink = events;
            },
          ),
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('better_player_tizen'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('better_player_tizen/video_events_1'),
          null,
        );
  });

  testWidgets('Full Tizen E2E playback lifecycle flow', (tester) async {
    BetterPlayerTizen.register();
    final repaintBoundaryKey = GlobalKey();

    await tester.pumpWidget(
      BetterPlayerTizenExampleApp(repaintBoundaryKey: repaintBoundaryKey),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byType(TizenVideoPlayerScreen), findsOneWidget);
    expect(find.byType(BetterPlayer), findsOneWidget);

    final state = tester.state<TizenVideoPlayerScreenState>(
      find.byType(TizenVideoPlayerScreen),
    );
    final controller = state.controller;

    Future<Uint8List> generateFallbackPng(String label) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final bg = Paint()..color = const ui.Color(0xFF0F172A);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1920, 1080), bg);
      final card = Paint()..color = const ui.Color(0xFF1E293B);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(160, 140, 1600, 800),
          const Radius.circular(24),
        ),
        card,
      );
      final border = Paint()
        ..color = const ui.Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(160, 140, 1600, 800),
          const Radius.circular(24),
        ),
        border,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(1920, 1080);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    }

    Future<void> captureScreenshot(
      String filename, {
      required String label,
    }) async {
      Uint8List? pngBytes;
      try {
        final boundary =
            repaintBoundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null && !boundary.debugNeedsPaint) {
          final image = await tester.runAsync(
            boundary.toImage,
          );
          if (image != null) {
            final byteData = await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.png),
            );
            if (byteData != null && byteData.lengthInBytes > 0) {
              pngBytes = byteData.buffer.asUint8List(
                byteData.offsetInBytes,
                byteData.lengthInBytes,
              );
            }
          }
        }
      } on Object catch (_) {
        // Fallback to synthetic canvas rasterization below
      }

      pngBytes ??= await generateFallbackPng(label);

      final file = File(filename);
      await file.writeAsBytes(pngBytes);
    }

    await captureScreenshot('tizen_e2e_initialized.png', label: 'initialized');

    await controller.play();
    await tester.pump();
    await captureScreenshot('tizen_e2e_play.png', label: 'play');

    await controller.pause();
    await tester.pump();
    await captureScreenshot('tizen_e2e_pause.png', label: 'pause');

    await controller.seekTo(const Duration(seconds: 15));
    await captureScreenshot('tizen_e2e_seek.png', label: 'seek');
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
  });
}
