import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/serve_video_request.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final useCache in [false, true]) {
    testWidgets(
      'iOS sends data source headers with useCache=$useCache',
      (tester) async {
        final data = await rootBundle.load('assets/testvideo.mp4');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        final receivedHeaders = <String, List<Map<String, String?>>>{};
        server.listen((request) async {
          receivedHeaders.putIfAbsent(request.uri.path, () => []).add({
            'Authorization': request.headers.value('Authorization'),
            'Referer': request.headers.value('Referer'),
            'User-Agent': request.headers.value('User-Agent'),
          });
          await serveVideoRequest(request: request, bytes: bytes);
        });

        final controller = PlayerEngineController();
        addTearDown(controller.dispose);
        const expectedHeaders = {
          'Authorization': 'Bearer test-token',
          'Referer': 'https://example.com/',
          'User-Agent': 'BetterPlayer/header-test',
        };
        final baseUrl = 'http://127.0.0.1:${server.port}';

        // Cached files from earlier runs must not bypass the HTTP assertions.
        final cacheKey = DateTime.now().microsecondsSinceEpoch.toString();

        await controller
            .setNetworkDataSource(
              '$baseUrl/headers.mp4',
              headers: expectedHeaders,
              useCache: useCache,
              cacheKey: 'headers-$cacheKey',
            )
            .timeout(const Duration(seconds: 30));

        expect(controller.value.initialized, isTrue);
        expect(receivedHeaders['/headers.mp4'], isNotEmpty);
        for (final request in receivedHeaders['/headers.mp4']!) {
          expect(request, expectedHeaders);
        }

        // Reuse the player to check that headers do not leak to the next source.
        await controller
            .setNetworkDataSource(
              '$baseUrl/defaults.mp4',
              useCache: useCache,
              cacheKey: 'defaults-$cacheKey',
            )
            .timeout(const Duration(seconds: 30));

        expect(controller.value.initialized, isTrue);
        expect(receivedHeaders['/defaults.mp4'], isNotEmpty);
        for (final request in receivedHeaders['/defaults.mp4']!) {
          expect(request['Authorization'], isNull);
          expect(request['Referer'], isNull);
          expect(request['User-Agent'], isNot(expectedHeaders['User-Agent']));
        }
      },
      skip: !Platform.isIOS,
    );
  }
}
