import 'package:better_player_platform_interface/better_player_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestBetterPlayerPlatform extends BetterPlayerPlatform {
  void emit(DownloadProgress progress) => emitDownloadProgress(progress);
}

class _RecordingDownloadCallback extends BetterPlayerDownloadCallback {
  final calls = <(String, DownloadState, String?)>[];

  @override
  void onDownloadState(String url, DownloadState state, String? error) {
    calls.add((url, state, error));
  }
}

void main() {
  const progress = DownloadProgress(
    url: 'https://example.com/video.mpd',
    state: DownloadState.downloading,
    bytesDownloaded: 512,
    totalBytes: 1024,
  );

  group('BetterPlayerDownloadCallback tests', () {
    test('receives the state of the download', () {
      final callback = _RecordingDownloadCallback();
      _TestBetterPlayerPlatform()
        ..setDownloadCallback(callback)
        ..emit(progress);

      expect(callback.calls, hasLength(1));
      expect(callback.calls.single.$1, progress.url);
      expect(callback.calls.single.$2, DownloadState.downloading);
      expect(callback.calls.single.$3, isNull);
    });

    test('receives the error of a failed download', () {
      final callback = _RecordingDownloadCallback();
      _TestBetterPlayerPlatform()
        ..setDownloadCallback(callback)
        ..emit(
          const DownloadProgress(
            url: 'https://example.com/video.mpd',
            state: DownloadState.failed,
            bytesDownloaded: 0,
            totalBytes: 0,
            error: 'No space left on device',
          ),
        );

      expect(callback.calls.single.$2, DownloadState.failed);
      expect(callback.calls.single.$3, 'No space left on device');
    });

    test('stops the calls when the callback is null', () {
      final callback = _RecordingDownloadCallback();
      _TestBetterPlayerPlatform()
        ..setDownloadCallback(callback)
        ..setDownloadCallback(null)
        ..emit(progress);

      expect(callback.calls, isEmpty);
    });

    test('the download progress stream keeps its subscribers', () async {
      final platform = _TestBetterPlayerPlatform();
      final callback = _RecordingDownloadCallback();
      platform.setDownloadCallback(callback);
      final events = <DownloadProgress>[];
      final subscription = platform.downloadProgressStream.listen(events.add);

      platform.emit(progress);
      await pumpEventQueue();

      expect(events, [progress]);
      expect(callback.calls, hasLength(1));
      await subscription.cancel();
    });
  });
}
