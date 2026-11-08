import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/utils/e2e_local_media_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('E2ELocalMediaServer', () {
    setUpAll(() async {
      await E2ELocalMediaServer.ensureStarted(force: true);
    });

    tearDownAll(() async {
      await E2ELocalMediaServer.stop();
    });

    test('starts on loopback and exposes local URLs', () {
      expect(E2ELocalMediaServer.isRunning, isTrue);
      expect(E2ELocalMediaServer.mp4Url, startsWith('http://127.0.0.1:'));
      expect(
        E2ELocalMediaServer.secondaryMp4Url,
        startsWith('http://127.0.0.1:'),
      );
      expect(E2ELocalMediaServer.hlsUrl, endsWith('/hls/master.m3u8'));
      expect(E2ELocalMediaServer.errorUrl, endsWith('/404.mp4'));
    });

    test(
      'serves MP4 with 200 OK and 206 Partial Content byte ranges',
      () async {
        final client = HttpClient();
        addTearDown(client.close);

        final headReq = await client.openUrl(
          'HEAD',
          Uri.parse(E2ELocalMediaServer.mp4Url),
        );
        final headRes = await headReq.close();
        expect(headRes.statusCode, HttpStatus.ok);
        expect(
          headRes.headers.value(HttpHeaders.acceptRangesHeader),
          'bytes',
        );
        final totalLength = headRes.contentLength;
        expect(totalLength, greaterThan(1000));

        final rangeReq = await client.getUrl(
          Uri.parse(E2ELocalMediaServer.mp4Url),
        );
        rangeReq.headers.set(HttpHeaders.rangeHeader, 'bytes=0-1');
        final rangeRes = await rangeReq.close();
        final rangeBytes = await rangeRes.fold<List<int>>(
          <int>[],
          (prev, element) => prev..addAll(element),
        );
        expect(rangeRes.statusCode, HttpStatus.partialContent);
        expect(
          rangeRes.headers.value(HttpHeaders.contentRangeHeader),
          'bytes 0-1/$totalLength',
        );
        expect(rangeBytes.length, 2);

        final badRangeReq = await client.getUrl(
          Uri.parse(E2ELocalMediaServer.mp4Url),
        );
        badRangeReq.headers.set(
          HttpHeaders.rangeHeader,
          'bytes=${totalLength + 100}-',
        );
        final badRangeRes = await badRangeReq.close();
        await badRangeRes.drain<void>();
        expect(
          badRangeRes.statusCode,
          HttpStatus.requestedRangeNotSatisfiable,
        );
      },
    );

    test(
      'serves HLS master playlist with 5 variants and MPEG-TS segment',
      () async {
        final asmsUtils = PlayerAsmsUtils();
        final result = await asmsUtils.getDataWithRedirectUrl(
          E2ELocalMediaServer.hlsUrl,
        );
        expect(result.data, isNotNull);

        final holder = await asmsUtils.parse(
          result.data!,
          result.effectiveUrl,
        );
        expect(holder.tracks, isNotNull);
        // Auto track + 5 quality variants.
        expect(holder.tracks!.length, 6);

        final client = HttpClient();
        addTearDown(client.close);

        final baseUri = Uri.parse(E2ELocalMediaServer.hlsUrl);
        final variantReq = await client.getUrl(
          baseUri.resolve('variant_0.m3u8'),
        );
        final variantRes = await variantReq.close();
        expect(variantRes.statusCode, HttpStatus.ok);
        await variantRes.drain<void>();

        final tsReq = await client.getUrl(baseUri.resolve('segment.ts'));
        final tsRes = await tsReq.close();
        final tsBytes = await tsRes.fold<List<int>>(
          <int>[],
          (prev, element) => prev..addAll(element),
        );
        expect(tsRes.statusCode, HttpStatus.ok);
        expect(tsBytes.isNotEmpty, isTrue);
        expect(tsBytes.length % 188, 0);
        expect(tsBytes.first, 0x47);
      },
    );

    test('serves 404 Not Found for errorUrl', () async {
      final client = HttpClient();
      addTearDown(client.close);

      final req = await client.getUrl(Uri.parse(E2ELocalMediaServer.errorUrl));
      final res = await req.close();
      await res.drain<void>();
      expect(res.statusCode, HttpStatus.notFound);
    });
  });
}
