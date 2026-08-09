import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:better_player/src/asms/better_player_asms_utils.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  Duration? connectionTimeout;
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
  MockHttpClientResponse() : super(Stream.value(utf8.encode('test data')));

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
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      throw UnimplementedError();

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
  group('BetterPlayerAsmsUtils tests', () {
    test('isDataSourceHls identifies HLS', () {
      expect(BetterPlayerAsmsUtils.isDataSourceHls('test.m3u8'), true);
      expect(BetterPlayerAsmsUtils.isDataSourceHls('test.mp4'), false);
    });

    test('isDataSourceDash identifies DASH', () {
      expect(BetterPlayerAsmsUtils.isDataSourceDash('test.mpd'), true);
      expect(BetterPlayerAsmsUtils.isDataSourceDash('test.mp4'), false);
    });

    test('isDataSourceAsms identifies ASMS', () {
      expect(BetterPlayerAsmsUtils.isDataSourceAsms('test.m3u8'), true);
      expect(BetterPlayerAsmsUtils.isDataSourceAsms('test.mpd'), true);
      expect(BetterPlayerAsmsUtils.isDataSourceAsms('test.mp4'), false);
    });

    test('parse identifies and parses HLS', () async {
      const data = '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1280000\nvideo.m3u8';
      final holder = await BetterPlayerAsmsUtils.parse(data, 'test.m3u8');
      expect(holder.tracks != null, true);
    });

    test('parse identifies and parses DASH', () async {
      const data =
          '<MPD xmlns="urn:mpeg:dash:schema:mpd:2011" profiles="urn:mpeg:dash:profile:isoff-on-demand:2011" type="static"><Period></Period></MPD>';
      final holder = await BetterPlayerAsmsUtils.parse(data, 'test.mpd');
      expect(holder.tracks != null, true);
    });

    test('getDataFromUrl fetches data', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final data = await BetterPlayerAsmsUtils.getDataFromUrl(
            'https://example.com/test.m3u8');
        expect(data, 'test data');
      }, TestHttpOverrides());
    });

    test('getDataFromUrl with headers', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final data = await BetterPlayerAsmsUtils.getDataFromUrl(
          'https://example.com/test.m3u8',
          {'Authorization': 'Bearer test'},
        );
        expect(data, 'test data');
      }, TestHttpOverrides());
    });
  });
}
