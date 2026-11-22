import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/better_player_test_utils.dart';
import '../../helpers/mock_player_engine_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BetterPlayerTestUtils.setupMockPlatform);

  group('PlayerDataSourceExtension', () {
    test(
      'setupDataSource with network source updates state and posts event',
      () async {
        final mockEngine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
            );

        final events = <PlayerEvent>[];
        controller.addEventsListener(events.add);

        final dataSource = PlayerDataSource(
          DataSourceType.network,
          'https://example.com/video.mp4',
          headers: {'Custom-Header': 'value1'},
        );

        await controller.setupDataSource(dataSource);

        expect(controller.betterPlayerDataSource, dataSource);
        expect(mockEngine.headers?['Custom-Header'], 'value1');
        expect(
          events.any(
            (e) => e.betterPlayerEventType == PlayerEventType.setupDataSource,
          ),
          isTrue,
        );

        controller.dispose();
      },
    );

    test(
      'setupDataSource with token DRM automatically injects authorization header',
      () async {
        final mockEngine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
            );

        final dataSource = PlayerDataSource(
          DataSourceType.network,
          'https://example.com/video.mp4',
          drmConfiguration: const DrmConfiguration(
            drmType: DrmType.token,
            token: 'Bearer test-token-123',
          ),
        );

        await controller.setupDataSource(dataSource);

        expect(
          mockEngine.headers?[PlayerEventConstants.authorizationHeader],
          'Bearer test-token-123',
        );

        controller.dispose();
      },
    );

    test(
      'setupDataSource with file source updates betterPlayerDataSource',
      () async {
        final mockEngine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
            );

        final dataSource = PlayerDataSource(
          DataSourceType.file,
          '/path/to/local/video.mp4',
        );

        await controller.setupDataSource(dataSource);

        expect(controller.betterPlayerDataSource, dataSource);

        controller.dispose();
      },
    );

    test(
      'setupDataSource configures subtitles in subtitlesSourceList',
      () async {
        final mockEngine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
            );

        final subSource = PlayerSubtitlesSource(
          type: PlayerSubtitlesSourceType.memory,
          name: 'English',
          content: 'WEBVTT\n\n00:00:01.000 --> 00:00:03.000\nHello',
          selectedByDefault: true,
        );

        final dataSource = PlayerDataSource(
          DataSourceType.network,
          'https://example.com/video.mp4',
          subtitles: [subSource],
        );

        await controller.setupDataSource(dataSource);

        expect(
          controller.betterPlayerSubtitlesSourceList.contains(subSource),
          isTrue,
        );

        controller.dispose();
      },
    );

    test(
      'retryDataSource re-executes setup and maintains data source',
      () async {
        final mockEngine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
            );

        final dataSource = PlayerDataSource(
          DataSourceType.network,
          'https://example.com/video.mp4',
        );

        await controller.setupDataSource(dataSource);
        expect(controller.betterPlayerDataSource, dataSource);

        await controller.retryDataSource();

        expect(controller.betterPlayerDataSource, dataSource);

        controller.dispose();
      },
    );

    test(
      'setupDataSource with const headers and token DRM does not throw UnsupportedError',
      () async {
        final mockEngine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
            );

        final dataSource = PlayerDataSource(
          DataSourceType.network,
          'https://example.com/video.mp4',
          headers: const {'X-Custom': 'abc'},
          drmConfiguration: const DrmConfiguration(
            drmType: DrmType.token,
            token: 'Bearer const-token',
          ),
        );

        await controller.setupDataSource(dataSource);

        expect(mockEngine.headers?['X-Custom'], 'abc');
        expect(
          mockEngine.headers?[PlayerEventConstants.authorizationHeader],
          'Bearer const-token',
        );
        expect(mockEngine.drmType, DrmType.token);
        expect(mockEngine.token, 'Bearer const-token');

        controller.dispose();
      },
    );

    test(
      'setupDataSource forwards drmType and token for file data source',
      () async {
        final mockEngine = MockPlayerEngineController();
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
            );

        final dataSource = PlayerDataSource(
          DataSourceType.file,
          '/path/to/video.mp4',
          drmConfiguration: const DrmConfiguration(
            drmType: DrmType.token,
            token: 'Bearer file-token',
          ),
        );

        await controller.setupDataSource(dataSource);

        expect(mockEngine.drmType, DrmType.token);
        expect(mockEngine.token, 'Bearer file-token');

        controller.dispose();
      },
    );

    test(
      'setupDataSource skips _initializeVideo when controller is disposed mid-setup',
      () async {
        final setupCompleter = Completer<void>();
        final mockEngine = _PendingSetDataSourceEngineController(
          setupCompleter,
        );
        final controller =
            BetterPlayerTestUtils.setupBetterPlayerMockController(
              controller: mockEngine,
              configuration: const PlayerConfiguration(autoPlay: true),
            );

        final dataSource = PlayerDataSource.network(
          'https://example.com/video.mp4',
        );

        final setupFuture = controller.setupDataSource(dataSource);
        controller.dispose(forceDispose: true);
        setupCompleter.complete();
        await setupFuture;

        expect(mockEngine.playCalled, isFalse);
      },
    );
  });
}

class _PendingSetDataSourceEngineController extends MockPlayerEngineController {
  _PendingSetDataSourceEngineController(this._completer);

  final Completer<void> _completer;
  bool playCalled = false;

  @override
  Future<void> setNetworkDataSource(
    String dataSource, {
    VideoFormat? formatHint,
    Map<String, String?>? headers,
    bool useCache = false,
    int? maxCacheSize,
    int? maxCacheFileSize,
    String? cacheKey,
    bool? showNotification,
    String? title,
    String? author,
    String? imageUrl,
    String? notificationChannelName,
    Duration? overriddenDuration,
    DrmType? drmType,
    String? token,
    String? licenseUrl,
    String? certificateUrl,
    Map<String, String>? drmHeaders,
    String? activityName,
    String? clearKey,
    DrmSecurityLevel? drmSecurityLevel,
    String? videoExtension,
  }) {
    return _completer.future;
  }

  @override
  Future<void> play() async {
    playCalled = true;
    await super.play();
  }
}
