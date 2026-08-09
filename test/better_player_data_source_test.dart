import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayerDataSource tests', () {
    test('Network factory', () {
      final source =
          BetterPlayerDataSource.network('https://example.com/video.mp4');
      expect(source.type, BetterPlayerDataSourceType.network);
      expect(source.url, 'https://example.com/video.mp4');
    });

    test('File factory', () {
      final source = BetterPlayerDataSource.file('/path/to/video.mp4');
      expect(source.type, BetterPlayerDataSourceType.file);
      expect(source.url, '/path/to/video.mp4');
    });

    test('Memory factory', () {
      final source = BetterPlayerDataSource.memory([1, 2, 3]);
      expect(source.type, BetterPlayerDataSourceType.memory);
      expect(source.bytes, [1, 2, 3]);
    });

    test('copyWith', () {
      final source =
          BetterPlayerDataSource.network('https://example.com/video.mp4');
      final newSource = source.copyWith(url: 'https://example.com/new.mp4');
      expect(newSource.url, 'https://example.com/new.mp4');
      expect(newSource.type, BetterPlayerDataSourceType.network);
    });
  });
}
