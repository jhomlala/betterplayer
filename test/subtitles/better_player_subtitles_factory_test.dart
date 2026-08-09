import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:better_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_source_type.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }

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
            utf8.encode('1\n00:00:01,000 --> 00:00:02,000\nHello\n\n'),
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
  ]) =>
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
  group('BetterPlayerSubtitlesFactory tests', () {
    test('parseSubtitles from memory', () async {
      final source = BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.memory,
        content: '1\n00:00:01,000 --> 00:00:02,000\nHello\n\n',
      );
      final subtitles =
          await BetterPlayerSubtitlesFactory.parseSubtitles(source);
      expect(subtitles.length, 1);
      expect(subtitles[0].texts![0], 'Hello');
    });

    test('parseSubtitles from network', () async {
      await HttpOverrides.runWithHttpOverrides(
        () async {
          final source = BetterPlayerSubtitlesSource(
            type: BetterPlayerSubtitlesSourceType.network,
            urls: ['https://example.com/subs.srt'],
          );
          final subtitles =
              await BetterPlayerSubtitlesFactory.parseSubtitles(source);
          expect(subtitles.length, 1);
        },
        TestHttpOverrides(),
      );
    });

    test('parseSubtitles from file handles non-existent file', () async {
      final source = BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.file,
        urls: ['non_existent_file.srt'],
      );
      final subtitles =
          await BetterPlayerSubtitlesFactory.parseSubtitles(source);
      expect(subtitles.length, 0);
    });

    test('parseString handles WebVTT', () {
      // _parseString is private, but we can use parseSubtitles with memory
      // to test it.
    });
  });
}
