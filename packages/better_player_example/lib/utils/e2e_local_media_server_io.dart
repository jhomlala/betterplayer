import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_player_example/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Local loopback HTTP media server for iOS E2E tests.
///
/// Serves MP4 and multi-variant HLS streams over `http://127.0.0.1:<port>` so
/// iOS Simulator E2E tests do not depend on `com.apple.trustd` TLS evaluation
/// or external CDNs.
class E2ELocalMediaServer {
  static HttpServer? _server;
  static Future<void>? _startFuture;
  static Uint8List? _mp4Bytes;
  static Uint8List? _tsBytes;

  static const String _masterPlaylist =
      '#EXTM3U\n'
      '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=2149280,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=1280x720,NAME="720"\n'
      'variant_0.m3u8\n'
      '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=246440,CODECS="mp4a.40.5,avc1.42000d",RESOLUTION=320x184,NAME="240"\n'
      'variant_1.m3u8\n'
      '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=460560,CODECS="mp4a.40.5,avc1.420016",RESOLUTION=512x288,NAME="380"\n'
      'variant_2.m3u8\n'
      '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=836280,CODECS="mp4a.40.2,avc1.64001f",RESOLUTION=848x480,NAME="480"\n'
      'variant_3.m3u8\n'
      '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=6221600,CODECS="mp4a.40.2,avc1.640028",RESOLUTION=1920x1080,NAME="1080"\n'
      'variant_4.m3u8\n';

  static const String _variantPlaylist =
      '#EXTM3U\n'
      '#EXT-X-VERSION:3\n'
      '#EXT-X-PLAYLIST-TYPE:VOD\n'
      '#EXT-X-TARGETDURATION:10\n'
      '#EXTINF:10.000,\n'
      'segment.ts\n'
      '#EXT-X-DISCONTINUITY\n'
      '#EXTINF:10.000,\n'
      'segment.ts\n'
      '#EXT-X-ENDLIST\n';

  static bool get isRunning => _server != null;

  static String get mp4Url => _server != null
      ? 'http://127.0.0.1:${_server!.port}/video.mp4'
      : Constants.bugBuckBunnyVideoUrl;

  static String get secondaryMp4Url => _server != null
      ? 'http://127.0.0.1:${_server!.port}/video_secondary.mp4'
      : Constants.forBiggerBlazesUrl;

  static String get hlsUrl => _server != null
      ? 'http://127.0.0.1:${_server!.port}/hls/master.m3u8'
      : Constants.hlsTestStreamUrl;

  static String get errorUrl => _server != null
      ? 'http://127.0.0.1:${_server!.port}/404.mp4'
      : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/404.mp4';

  static Future<void> ensureStarted({bool force = false}) async {
    if (!force && defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    if (_server != null) {
      return;
    }
    await (_startFuture ??= _start());
  }

  static Future<void> stop() async {
    final server = _server;
    _server = null;
    _startFuture = null;
    await server?.close(force: true);
  }

  static Future<void> _start() async {
    try {
      _mp4Bytes ??= await _loadAssetBytes('assets/testvideo.mp4');
      _tsBytes ??= await _loadAssetBytes('assets/testvideo.ts');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      unawaited(server.forEach(_handleRequest));
    } on Object catch (e) {
      debugPrint('E2ELocalMediaServer failed to start: $e');
      _startFuture = null;
    }
  }

  static Future<Uint8List> _loadAssetBytes(String assetPath) async {
    for (final candidate in [
      assetPath,
      'packages/better_player_example/$assetPath',
    ]) {
      final file = File(candidate);
      if (file.existsSync()) {
        return file.readAsBytes();
      }
    }
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    try {
      if (path == '/video.mp4' || path == '/video_secondary.mp4') {
        final bytes = _mp4Bytes ??= await _loadAssetBytes(
          'assets/testvideo.mp4',
        );
        await _serveBinary(
          request: request,
          bytes: bytes,
          contentType: 'video/mp4',
        );
      } else if (path == '/hls/master.m3u8') {
        await _serveText(
          request: request,
          body: _masterPlaylist,
          contentType: 'application/vnd.apple.mpegurl',
        );
      } else if (path.startsWith('/hls/variant_') && path.endsWith('.m3u8')) {
        await _serveText(
          request: request,
          body: _variantPlaylist,
          contentType: 'application/vnd.apple.mpegurl',
        );
      } else if (path == '/hls/segment.ts') {
        final bytes = _tsBytes ??= await _loadAssetBytes('assets/testvideo.ts');
        await _serveBinary(
          request: request,
          bytes: bytes,
          contentType: 'video/mp2t',
        );
      } else {
        await _serveNotFound(request);
      }
    } on Object catch (_) {
      try {
        await request.response.close();
      } on Object catch (_) {}
    }
  }

  static Future<void> _serveText({
    required HttpRequest request,
    required String body,
    required String contentType,
  }) async {
    final encoded = utf8.encode(body);
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.set(HttpHeaders.contentTypeHeader, contentType)
      ..headers.set(HttpHeaders.contentLengthHeader, encoded.length)
      ..headers.set('Access-Control-Allow-Origin', '*');
    if (request.method != 'HEAD') {
      request.response.add(encoded);
    }
    await request.response.close();
  }

  static Future<void> _serveBinary({
    required HttpRequest request,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final total = bytes.length;
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    final range = _parseByteRange(rangeHeader: rangeHeader, total: total);

    request.response.headers
      ..set(HttpHeaders.contentTypeHeader, contentType)
      ..set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..set('Access-Control-Allow-Origin', '*');

    if (rangeHeader != null && range == null) {
      request.response
        ..statusCode = HttpStatus.requestedRangeNotSatisfiable
        ..headers.set(HttpHeaders.contentRangeHeader, 'bytes */$total');
      await request.response.close();
      return;
    }

    if (range != null) {
      final length = range.end - range.start + 1;
      request.response
        ..statusCode = HttpStatus.partialContent
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes ${range.start}-${range.end}/$total',
        )
        ..headers.set(HttpHeaders.contentLengthHeader, length);
      if (request.method != 'HEAD') {
        request.response.add(
          Uint8List.sublistView(bytes, range.start, range.end + 1),
        );
      }
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.set(HttpHeaders.contentLengthHeader, total);
    if (request.method != 'HEAD') {
      request.response.add(bytes);
    }
    await request.response.close();
  }

  static ({int start, int end})? _parseByteRange({
    required String? rangeHeader,
    required int total,
  }) {
    if (rangeHeader == null || !rangeHeader.startsWith('bytes=')) {
      return null;
    }
    final spec = rangeHeader.substring('bytes='.length).split(',').first.trim();
    final parts = spec.split('-');
    if (parts.length != 2) {
      return null;
    }
    final start = int.tryParse(parts[0]);
    if (start == null || start < 0 || start >= total) {
      return null;
    }
    final parsedEnd = parts[1].isEmpty ? total - 1 : int.tryParse(parts[1]);
    if (parsedEnd == null || parsedEnd < start) {
      return null;
    }
    final end = parsedEnd >= total ? total - 1 : parsedEnd;
    return (start: start, end: end);
  }

  static Future<void> _serveNotFound(HttpRequest request) async {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }
}
