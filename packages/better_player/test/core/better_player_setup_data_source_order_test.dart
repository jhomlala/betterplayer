import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_test_utils.dart';
import '../helpers/mock_player_engine_controller.dart';

class _DelayedMockPlayerEngineController extends MockPlayerEngineController {
  final Map<String, Completer<void>> completers = {};

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
    String? licenseUrl,
    String? certificateUrl,
    Map<String, String>? drmHeaders,
    String? activityName,
    String? clearKey,
    DrmSecurityLevel? drmSecurityLevel,
    String? videoExtension,
  }) async {
    final completer = Completer<void>();
    completers[dataSource] = completer;
    await completer.future;
  }
}

void main() {
  test(
    'setupDataSource controller event is posted after setup completes',
    () async {
      final mock = MockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );

      final events = <PlayerControllerEvent>[];
      controller.controllerEventStream.listen(events.add);

      await controller.setupDataSource(
        PlayerDataSource.file('test/video.mp4'),
      );

      await Future<void>.delayed(Duration.zero);
      // Verify that setupDataSource controller event was posted
      expect(events.contains(PlayerControllerEvent.setupDataSource), true);
    },
  );

  test(
    'superseded setupDataSource call does not overwrite newer data source error or state',
    () async {
      final mock = _DelayedMockPlayerEngineController();
      final controller = BetterPlayerTestUtils.setupBetterPlayerMockController(
        controller: mock,
      );

      final playerEvents = <PlayerEvent>[];
      controller.addEventsListener(playerEvents.add);

      final firstSource = PlayerDataSource.network('https://example.com/1.mp4');
      final secondSource = PlayerDataSource.network(
        'https://example.com/404.mp4',
      );

      final firstFuture = controller.setupDataSource(firstSource);
      final secondFuture = controller.setupDataSource(secondSource);

      mock.completers['https://example.com/404.mp4']!.completeError(
        Exception('404 Not Found'),
      );
      await secondFuture;

      expect(
        playerEvents.any(
          (e) => e.betterPlayerEventType == PlayerEventType.exception,
        ),
        isTrue,
      );
      expect(controller.videoPlayerValue?.hasError, isTrue);

      // Now complete the superseded first source; it must not emit setupDataSource
      mock.completers['https://example.com/1.mp4']!.complete();
      await firstFuture;

      expect(
        playerEvents.where(
          (e) => e.betterPlayerEventType == PlayerEventType.setupDataSource,
        ),
        isEmpty,
      );
      expect(controller.betterPlayerDataSource, same(secondSource));
    },
  );
}
