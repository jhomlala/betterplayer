import 'package:better_player/better_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPlayer ASMS models tests', () {
    test('PlayerAsmsSubtitle initialization', () {
      final subtitle = PlayerAsmsSubtitle(
        name: 'English',
        language: 'en',
        isDefault: true,
      );
      expect(subtitle.name, 'English');
      expect(subtitle.language, 'en');
      expect(subtitle.isDefault, true);
    });

    test('PlayerAsmsSubtitleSegment initialization', () {
      final segment = PlayerAsmsSubtitleSegment(
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        'https://example.com/seg1.vtt',
      );
      expect(segment.startTime, const Duration(seconds: 1));
      expect(segment.endTime, const Duration(seconds: 2));
      expect(segment.realUrl, 'https://example.com/seg1.vtt');
    });

    test('PlayerAsmsTrack equality', () {
      final track1 = PlayerAsmsTrack(
        '1',
        1920,
        1080,
        5000,
        30,
        'avc1',
        'video/mp4',
      );
      final track2 = PlayerAsmsTrack(
        '1',
        1920,
        1080,
        5000,
        30,
        'avc1',
        'video/mp4',
      );
      final track3 = PlayerAsmsTrack(
        '2',
        1280,
        720,
        2000,
        30,
        'avc1',
        'video/mp4',
      );

      expect(track1 == track2, true);
      expect(track1 == track3, false);
      expect(track1.hashCode, track1.hashCode);
    });

    test('PlayerAsmsTrack.defaultTrack initialization', () {
      final track = PlayerAsmsTrack.defaultTrack();
      expect(track.id, '');
      expect(track.width, 0);
      expect(track.height, 0);
      expect(track.bitrate, 0);
      expect(track.frameRate, 0);
      expect(track.codecs, '');
      expect(track.mimeType, '');
    });

    test('PlayerAsmsAudioTrack initialization', () {
      final audioTrack = PlayerAsmsAudioTrack(
        id: 1,
        segmentAlignment: true,
        label: 'English',
        language: 'en',
        url: 'https://example.com/audio.m3u8',
        mimeType: 'audio/mp4',
      );
      expect(audioTrack.id, 1);
      expect(audioTrack.segmentAlignment, true);
      expect(audioTrack.label, 'English');
      expect(audioTrack.language, 'en');
      expect(audioTrack.url, 'https://example.com/audio.m3u8');
      expect(audioTrack.mimeType, 'audio/mp4');
    });

    test('PlayerAsmsDataHolder initialization', () {
      final tracks = [
        PlayerAsmsTrack.defaultTrack(),
      ];
      final subtitles = [
        PlayerAsmsSubtitle(name: 'Test', language: 'en'),
      ];
      final audios = [
        PlayerAsmsAudioTrack(id: 1),
      ];

      final dataHolder = PlayerAsmsDataHolder(
        tracks: tracks,
        subtitles: subtitles,
        audios: audios,
      );

      expect(dataHolder.tracks, tracks);
      expect(dataHolder.subtitles, subtitles);
      expect(dataHolder.audios, audios);
    });
  });
}
