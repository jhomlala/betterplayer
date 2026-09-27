# Subtitles Reference

Better Player supports SRT and WebVTT subtitles (including HTML tags, WebVTT cue alignment, and `X-TIMESTAMP-MAP` MPEG-TS sync) from network, file, memory, or adaptive stream manifests (HLS/DASH).

## 1. Single Subtitle Track

Use `PlayerSubtitlesSource.single` for a single subtitle file:

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/video.mp4',
  subtitles: PlayerSubtitlesSource.single(
    type: PlayerSubtitlesSourceType.network,
    name: 'English',
    url: 'https://example.com/subtitles_en.vtt',
    selectedByDefault: true,
  ),
);
```

## 2. Multiple Subtitle Tracks

Pass a list of `PlayerSubtitlesSource` items to `PlayerDataSource.subtitles`:

```dart
final dataSource = PlayerDataSource(
  DataSourceType.network,
  'https://example.com/video.mp4',
  subtitles: [
    PlayerSubtitlesSource(
      type: PlayerSubtitlesSourceType.network,
      name: 'English',
      urls: ['https://example.com/subtitles_en.vtt'],
      selectedByDefault: true,
    ),
    PlayerSubtitlesSource(
      type: PlayerSubtitlesSourceType.network,
      name: 'Polish',
      urls: ['https://example.com/subtitles_pl.srt'],
    ),
  ],
);
```

## 3. Adaptive Stream (HLS / DASH) Embedded Subtitles

Embedded HLS/DASH subtitles are parsed automatically when `useAsmsSubtitles: true` (the default on `PlayerDataSource`). Set `useAsmsSubtitles: false` if you only want manually provided `subtitles`.

## 4. Styling Subtitles (`PlayerSubtitlesConfiguration`)

Customize font, outline, alignment, and padding in `PlayerConfiguration`:

```dart
const configuration = PlayerConfiguration(
  subtitlesConfiguration: PlayerSubtitlesConfiguration(
    fontSize: 18,
    fontColor: Colors.white,
    outlineEnabled: true,
    outlineColor: Colors.black,
    outlineSize: 2,
    backgroundColor: Colors.black54,
    alignment: Alignment.bottomCenter,
    bottomPadding: 24,
  ),
);
```

## 5. Programmatic Subtitle Control

* Switch active subtitle track at runtime:
  ```dart
  await _controller.setupSubtitleSource(subtitleSource);
  ```
* Disable subtitles:
  ```dart
  await _controller.setupSubtitleSource(
    PlayerSubtitlesSource(type: PlayerSubtitlesSourceType.none),
  );
  ```
* Update subtitle styling at runtime:
  ```dart
  _controller.setPlayerSubtitlesConfiguration(
    const PlayerSubtitlesConfiguration(fontSize: 22, fontColor: Colors.yellow),
  );
  ```
* Read currently displayed subtitle line:
  ```dart
  final currentLine = _controller.renderedSubtitle;
  ```
