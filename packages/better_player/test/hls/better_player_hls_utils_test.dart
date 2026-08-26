import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_player/src/hls/better_player_hls_utils.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  Duration? connectionTimeout;

  @override
  bool autoUncompress = true;

  @override
  void close({bool force = false}) {}
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class MockHttpClientResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  MockHttpClientResponse()
    : super(
        Stream.value(
          utf8.encode('''
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXTINF:10.0,
segment1.vtt
#EXTINF:10.0,
segment2.vtt
'''),
        ),
      );

  @override
  int get statusCode => 200;

  @override
  int get contentLength => -1;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get persistentConnection => true;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnimplementedError();

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  List<Cookie> get cookies => [];

  @override
  String get reasonPhrase => 'OK';

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;
}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BetterPlayerHlsUtils advanced tests', () {
    test('parseSubtitles handles segmented subtitles', () async {
      await HttpOverrides.runWithHttpOverrides(
        () async {
          // This calls _parseSubtitlesPlaylist internally via parseSubtitles
          // if the master playlist data has subtitles.
          // But _parseSubtitlesPlaylist is private.
          // We can test parseSubtitles which calls it.

          const masterData = '''
#EXTM3U
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",URI="subs.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=1280000,SUBTITLES="subs"
video.m3u8
''';
          final subtitles = await BetterPlayerHlsUtils.parseSubtitles(
            masterData,
            'https://example.com/master.m3u8',
          );

          expect(subtitles.length, 1);
          expect(subtitles[0].name, 'English');
          expect(subtitles[0].isSegmented, true);
          expect(subtitles[0].segments?.length, 2);
          expect(subtitles[0].segments?[0].startTime, Duration.zero);
          expect(
            subtitles[0].segments?[0].endTime,
            const Duration(seconds: 10),
          );
          expect(
            subtitles[0].segments?[1].startTime,
            const Duration(seconds: 10),
          );
          expect(
            subtitles[0].segments?[1].endTime,
            const Duration(seconds: 20),
          );
        },
        TestHttpOverrides(),
      );
    });
  });
}
