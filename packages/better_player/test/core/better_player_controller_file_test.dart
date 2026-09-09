import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/better_player_mock_controller.dart';

class MockPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements BetterPlayerPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockPlatform mockPlatform;
  late StreamController<VideoEvent> eventController;

  setUpAll(() {
    registerFallbackValue(DataSource(sourceType: DataSourceType.network));
    
    // Mock path_provider
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return '.'; // Return current directory as temp dir for tests
    });
  });

  setUp(() {
    mockPlatform = MockPlatform();
    BetterPlayerPlatform.instance = mockPlatform;
    eventController = StreamController<VideoEvent>.broadcast();

    // Default behaviors for mock platform
    when(() => mockPlatform.setupLogCallback(any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.create(
          bufferingConfiguration: any(named: 'bufferingConfiguration'),
        )).thenAnswer((_) async => 1);
    when(() => mockPlatform.videoEventsFor(any()))
        .thenAnswer((_) => eventController.stream);
    when(() => mockPlatform.setDataSource(any(), any()))
        .thenAnswer((invocation) async {
      // Send initialized event when data source is set
      Timer.run(() {
        if (!eventController.isClosed) {
          eventController.add(VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 10),
            key: null,
          ));
        }
      });
    });
    when(() => mockPlatform.setLooping(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.setVolume(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.setSpeed(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.pause(any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.play(any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.seekTo(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.setTrackParameters(any(), any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    eventController.close();
  });

  group('BetterPlayerController File Source tests', () {
    test('setupDataSource with file source uses file:// URI', () async {
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
      );

      const filePath = '/path/to/video.mp4';
      final dataSource = PlayerDataSource.file(filePath);

      await controller.setupDataSource(dataSource);

      // Verify that the platform's setDataSource was called with the correct URI
      verify(() => mockPlatform.setDataSource(
            any(),
            any(
              that: predicate<DataSource>((ds) =>
                  ds.uri == 'file://$filePath' &&
                  ds.sourceType == DataSourceType.file),
            ),
          )).called(1);
    });

    test(
        'setupDataSource with memory source creates temp file and uses file:// URI',
        () async {
      final controller = BetterPlayerMockController(
        const PlayerConfiguration(),
      );

      final bytes = [1, 2, 3, 4];
      final dataSource = PlayerDataSource.memory(bytes);

      await controller.setupDataSource(dataSource);

      // For memory source, it creates a temp file and calls setDataSource with type 'file' and 'file://' URI
      verify(() => mockPlatform.setDataSource(
            any(),
            any(
              that: predicate<DataSource>((ds) =>
                  ds.uri!.startsWith('file://') &&
                  ds.uri!.contains('better_player_') &&
                  ds.sourceType == DataSourceType.file),
            ),
          )).called(1);

      // Clean up controller which should delete the temp file
      controller.dispose(forceDispose: true);
    });
  });
}
