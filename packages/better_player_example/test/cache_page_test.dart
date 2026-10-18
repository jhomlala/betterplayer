import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/pages/cache_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/mock_better_player_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBetterPlayerPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockBetterPlayerPlatform();
    BetterPlayerPlatform.instance = mockPlatform;
  });

  group('CachePage Tests', () {
    testWidgets('renders CachePage controls and buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CachePage(),
        ),
      );
      await tester.pump();

      expect(find.text('Video Caching'), findsOneWidget);
      expect(find.text('Native Cache & Pre-caching'), findsOneWidget);
      expect(find.text('Play Video'), findsOneWidget);
      expect(find.text('Start Pre-cache'), findsOneWidget);
      expect(find.text('Stop Pre-cache'), findsOneWidget);
      expect(find.text('Clear Cache'), findsOneWidget);
    });

    testWidgets(
      'start pre-cache displays progress card and reacts to progress',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final completer = Completer<void>();
        mockPlatform.preCacheHandler = (dataSource, preCacheSize, onProgress) =>
            completer.future;

        await tester.pumpWidget(
          const MaterialApp(
            home: CachePage(),
          ),
        );
        await tester.pump();

        // Tap Start Pre-cache
        await tester.tap(find.text('Start Pre-cache'));
        await tester.pump();

        expect(mockPlatform.preCacheCalls.length, 1);
        expect(find.text('Pre-caching in progress...'), findsOneWidget);

        // Emit progress event matching the video URL
        BetterPlayerPlatform.instance.emitPreCacheProgress(
          PreCacheProgress(
            url: mockPlatform.preCacheCalls.first.uri!,
            cacheKey: 'testCacheKey',
            progress: 0.5,
            bytesDownloaded: 5 * 1024 * 1024,
            totalBytes: 10 * 1024 * 1024,
          ),
        );
        await tester.pump();

        expect(find.text('50.0%'), findsOneWidget);
        expect(find.text('5.00 MB / 10.00 MB'), findsOneWidget);

        // Complete preCache
        completer.complete();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();

        expect(find.text('Pre-cache completed'), findsOneWidget);

        // Tap Clear Cache
        await tester.tap(find.text('Clear Cache'));
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Pre-cache completed'), findsNothing);
      },
    );
  });
}
