import 'package:better_player/better_player.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:better_player_tizen_example/main.dart';
import 'package:flutter/services.dart';
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
    await tester.pumpWidget(const BetterPlayerTizenExampleApp());
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

    await controller.play();
    await controller.pause();
    await controller.seekTo(const Duration(seconds: 15));
    await controller.setVolume(0.5);
    await controller.setSpeed(1.5);
    await controller.setLooping(false);

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
