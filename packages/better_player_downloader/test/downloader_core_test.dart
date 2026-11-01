import 'package:better_player_downloader/src/downloader_core.dart';
import 'package:better_player_downloader/src/models/download_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('better_player_downloader'),
          (call) async => true,
        );
  });

  test('validateRequest returns error for empty url', () {
    final result = validateRequest(const DownloadRequest(url: ''));
    expect(result, isA<DownloadErr>());
  });

  test('validateRequest requires native service for .mpd', () {
    final result = validateRequest(
      const DownloadRequest(url: 'https://example.com/video.mpd'),
    );
    expect(result, isA<DownloadRequiresNativeService>());
  });

  test('validateRequest returns ok for valid url', () {
    final result = validateRequest(
      const DownloadRequest(url: 'https://example.com/video.mp4'),
    );
    expect(result, isA<DownloadOk>());
  });
}
