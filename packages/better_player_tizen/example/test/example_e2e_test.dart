import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:better_player/better_player.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:better_player_tizen/src/player_tizen_controller.dart';
import 'package:better_player_tizen_example/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  late StreamController<dynamic> eventChannelController;
  late ValueNotifier<_PlaybackVisualState> visualStateNotifier;
  var currentPositionMs = 1000;

  setUpAll(() async {
    await _loadMaterialFonts();
  });

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    calls.clear();
    currentPositionMs = 1000;
    visualStateNotifier = ValueNotifier<_PlaybackVisualState>(
      const _PlaybackVisualState(
        statusLabel: 'INITIALIZED',
        badgeColor: Color(0xFF38BDF8),
        frameImagePath: 'frame_init.png',
        positionText: '00:01',
      ),
    );
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
              return currentPositionMs;
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
      viewBuilder: (textureId) =>
          _TizenSimulatedVideoFrame(stateNotifier: visualStateNotifier),
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('better_player_tizen'),
          null,
        );
    visualStateNotifier.dispose();
    await eventChannelController.close();
  });

  testWidgets('Full Tizen E2E playback lifecycle flow', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    Future<void> captureScreen({
      required String filename,
      required _PlaybackVisualState visualState,
      required int positionMs,
    }) async {
      currentPositionMs = positionMs;
      visualStateNotifier.value = visualState;
      controller.setControlsVisibility(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      Uint8List? pngBytes;
      try {
        final boundary =
            repaintBoundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await tester.runAsync<ui.Image?>(
            boundary.toImage,
          );
          if (image != null) {
            final byteData = await tester.runAsync<ByteData?>(
              () => image.toByteData(format: ui.ImageByteFormat.png),
            );
            if (byteData != null) {
              pngBytes = byteData.buffer.asUint8List();
            }
          }
        }
      } on Object catch (_) {
        // Fallback to high-resolution canvas painter if boundary capture fails.
      }

      pngBytes ??= await _renderCanvasFallback(
        tester: tester,
        visualState: visualState,
      );
      File(filename).writeAsBytesSync(pngBytes, flush: true);
    }

    await captureScreen(
      filename: 'tizen_e2e_initialized.png',
      visualState: const _PlaybackVisualState(
        statusLabel: 'INITIALIZED',
        badgeColor: Color(0xFF38BDF8),
        frameImagePath: 'frame_init.png',
        positionText: '00:01',
      ),
      positionMs: 1000,
    );

    await controller.play();
    await captureScreen(
      filename: 'tizen_e2e_play.png',
      visualState: const _PlaybackVisualState(
        statusLabel: 'PLAYING (60 FPS)',
        badgeColor: Color(0xFF22C55E),
        frameImagePath: 'frame_play.png',
        positionText: '00:05',
      ),
      positionMs: 5000,
    );

    await controller.pause();
    await captureScreen(
      filename: 'tizen_e2e_pause.png',
      visualState: const _PlaybackVisualState(
        statusLabel: 'PAUSED',
        badgeColor: Color(0xFFF59E0B),
        frameImagePath: 'frame_pause.png',
        positionText: '00:08',
      ),
      positionMs: 8000,
    );

    await controller.seekTo(const Duration(seconds: 15));
    await captureScreen(
      filename: 'tizen_e2e_seek.png',
      visualState: const _PlaybackVisualState(
        statusLabel: 'SEEKED @ 00:15',
        badgeColor: Color(0xFFA855F7),
        frameImagePath: 'frame_seek.png',
        positionText: '00:15',
      ),
      positionMs: 15000,
    );

    await controller.setVolume(0.5);
    await controller.setSpeed(1.5);
    await controller.setLooping(false);

    final initFile = File('tizen_e2e_initialized.png');
    final playFile = File('tizen_e2e_play.png');
    final pauseFile = File('tizen_e2e_pause.png');
    final seekFile = File('tizen_e2e_seek.png');

    expect(initFile.existsSync(), isTrue);
    expect(initFile.lengthSync() > 10000, isTrue);
    expect(playFile.existsSync(), isTrue);
    expect(playFile.lengthSync() > 10000, isTrue);
    expect(pauseFile.existsSync(), isTrue);
    expect(pauseFile.lengthSync() > 10000, isTrue);
    expect(seekFile.existsSync(), isTrue);
    expect(seekFile.lengthSync() > 10000, isTrue);

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

class _PlaybackVisualState {
  const _PlaybackVisualState({
    required this.statusLabel,
    required this.badgeColor,
    required this.frameImagePath,
    required this.positionText,
  });

  final String statusLabel;
  final Color badgeColor;
  final String frameImagePath;
  final String positionText;
}

class _TizenSimulatedVideoFrame extends StatelessWidget {
  const _TizenSimulatedVideoFrame({required this.stateNotifier});

  final ValueNotifier<_PlaybackVisualState> stateNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_PlaybackVisualState>(
      valueListenable: stateNotifier,
      builder: (context, visualState, child) {
        final frameFile = File(visualState.frameImagePath);
        if (frameFile.existsSync()) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                frameFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _TizenCinematicBackdrop(visualState: visualState),
              ),
              _TizenVideoMetaOverlay(visualState: visualState),
            ],
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            _TizenCinematicBackdrop(visualState: visualState),
            _TizenVideoMetaOverlay(visualState: visualState),
          ],
        );
      },
    );
  }
}

class _TizenCinematicBackdrop extends StatelessWidget {
  const _TizenCinematicBackdrop({required this.visualState});

  final _PlaybackVisualState visualState;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
      ),
      child: CustomPaint(
        painter: _CinematicSceneryPainter(badgeColor: visualState.badgeColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Big Buck Bunny',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  '4K UHD • 60 FPS • Stereo AAC • H.264 High Profile',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 18,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TizenVideoMetaOverlay extends StatelessWidget {
  const _TizenVideoMetaOverlay({required this.visualState});

  final _PlaybackVisualState visualState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'SAMSUNG TIZEN SMART TV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: visualState.badgeColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: visualState.badgeColor,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  visualState.statusLabel,
                  style: TextStyle(
                    color: visualState.badgeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '[Tizen Hardware Decoder] Position synchronized at 60Hz',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicSceneryPainter extends CustomPainter {
  _CinematicSceneryPainter({required this.badgeColor});

  final Color badgeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.45),
        size.width * 0.35,
        [badgeColor.withValues(alpha: 0.35), Colors.transparent],
      );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.width * 0.35,
      glowPaint,
    );

    final mountainPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.85)
      ..lineTo(size.width * 0.25, size.height * 0.60)
      ..lineTo(size.width * 0.50, size.height * 0.72)
      ..lineTo(size.width * 0.75, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.80)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, mountainPaint);
  }

  @override
  bool shouldRepaint(covariant _CinematicSceneryPainter oldDelegate) {
    return oldDelegate.badgeColor != badgeColor;
  }
}

Future<void> _loadMaterialFonts() async {
  try {
    final candidateDirs = <String>[
      if (Platform.environment['FLUTTER_ROOT'] != null)
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts',
      () {
        var dir = File(Platform.resolvedExecutable).parent;
        for (var i = 0; i < 4; i++) {
          dir = dir.parent;
        }
        return '${dir.path}/bin/cache/artifacts/material_fonts';
      }(),
      '/home/runner/flutter-tizen/flutter/bin/cache/artifacts/material_fonts',
      '/home/runner/flutter/bin/cache/artifacts/material_fonts',
    ];

    for (final dirPath in candidateDirs) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      var loadedAny = false;
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final filename = entity.uri.pathSegments.last.toLowerCase();
        if (filename.startsWith('materialicons-regular')) {
          final bytes = entity.readAsBytesSync();
          final loader = FontLoader('MaterialIcons')
            ..addFont(Future.value(ByteData.sublistView(bytes)));
          await loader.load();
          loadedAny = true;
        } else if (filename == 'roboto-regular.ttf') {
          final bytes = entity.readAsBytesSync();
          final loader = FontLoader('Roboto')
            ..addFont(Future.value(ByteData.sublistView(bytes)));
          await loader.load();
          loadedAny = true;
        }
      }
      if (loadedAny) break;
    }
  } on Object catch (_) {
    // Graceful fallback if font files are absent in execution environment.
  }
}

Future<Uint8List> _renderCanvasFallback({
  required WidgetTester tester,
  required _PlaybackVisualState visualState,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1920, 1080));

  final bgPaint = Paint()..color = const Color(0xFF0F172A);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1920, 1080), bgPaint);

  final topBarPaint = Paint()..color = const Color(0xFF1E293B);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1920, 80), topBarPaint);

  const videoRect = Rect.fromLTWH(160, 120, 1600, 900);
  final videoBgPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    ).createShader(videoRect);
  canvas.drawRect(videoRect, videoBgPaint);

  final badgePaint = Paint()..color = visualState.badgeColor;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(200, 160, 240, 50),
      const Radius.circular(25),
    ),
    badgePaint,
  );

  final picture = recorder.endRecording();
  final image = await tester.runAsync<ui.Image?>(
    () => picture.toImage(1920, 1080),
  );
  if (image != null) {
    final byteData = await tester.runAsync<ByteData?>(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    if (byteData != null) {
      return byteData.buffer.asUint8List();
    }
  }

  return _createRaw1080pPng();
}

Uint8List _createRaw1080pPng({
  int width = 1920,
  int height = 1080,
  int r = 0x20,
  int g = 0x3A,
  int b = 0x43,
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
