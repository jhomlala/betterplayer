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
  });
}
