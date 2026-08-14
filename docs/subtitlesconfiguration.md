## Subtitles source
Subtitles can be configured from 3 different sources: file, network and memory. Subtitles source is passed in `BetterPlayerDataSource`:

Network subtitles:
```dart
var dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    subtitles: BetterPlayerSubtitlesSource.single(
        type: BetterPlayerSubtitlesSourceType.network,
        url: "https://dl.dropboxusercontent.com/s/71nzjo2ux3evxqk/example_subtitles.srt"
    ),
);
```

File subtitles:
```dart
var dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.file,
    "${directory.path}/testvideo.mp4",
    subtitles: BetterPlayerSubtitlesSource.single(
        type: BetterPlayerSubtitlesSourceType.file,
        url: "${directory.path}/example_subtitles.srt",
    ),
);
```

You can pass multiple subtitles for one video:

```dart
var dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
    liveStream: false,
    useAsmsSubtitles: true,
    hlsTrackNames: ["Low quality", "Not so low quality", "Medium quality"],
    subtitles: [
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          name: "EN",
          urls: [
            "https://dl.dropboxusercontent.com/s/71nzjo2ux3evxqk/example_subtitles.srt"
          ],
        ),

        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          name: "DE",
          urls: [
            "https://dl.dropboxusercontent.com/s/71nzjo2ux3evxqk/example_subtitles.srt"
          ],
        ),
    ],
);
```


Possible `BetterPlayerSubtitlesSource` configuration options:
```dart
///Source type
final BetterPlayerSubtitlesSourceType? type;

///Name of the subtitles, default value is "Default subtitles"
final String? name;

///Url of the subtitles, used with file or network subtitles
final List<String?>? urls;

///Content of subtitles, used when type is memory
final String? content;

///Subtitles selected by default, without user interaction
final bool? selectedByDefault;

///Additional headers used in HTTP request. Works only for
/// [BetterPlayerSubtitlesSourceType.memory] source type.
final Map<String, String>? headers;

///Is ASMS segmented source (more than 1 subtitle file). This shouldn't be
///configured manually.
final bool? asmsIsSegmented;

///Max. time between segments in milliseconds. This shouldn't be configured
/// manually.
final int? asmsSegmentsTime;

///List of segments (start,end,url of the segment). This shouldn't be
///configured manually.
final List<BetterPlayerAsmsSubtitleSegment>? asmsSegments;
```


## Subtitles configuration

Subtitles can be configured with `BetterPlayerSubtitlesConfiguration` class. Instance of this configuration should be passed to `BetterPlayerConfiguration`.

```dart
var betterPlayerConfiguration = BetterPlayerConfiguration(
    subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
        fontSize: 20,
        fontColor: Colors.green,
    ),
);
```

Possible configuration options:
```dart
///Subtitle font size
final double fontSize;

///Subtitle font color
final Color fontColor;

///Enable outline (border) of the text
final bool outlineEnabled;

///Color of the outline stroke
final Color outlineColor;

///Outline stroke size
final double outlineSize;

///Font family of the subtitle
final String fontFamily;

///Left padding of the subtitle
final double leftPadding;

///Right padding of the subtitle
final double rightPadding;

///Bottom padding of the subtitle
final double bottomPadding;

///Alignment of the subtitle
final Alignment alignment;

///Background color of the subtitle
final Color backgroundColor;

///Subtitles selected by default, without user interaction
final bool selectedByDefault;
```

## Current subtitle

To get currently displayed subtitle, use `renderedSubtitle` in `BetterPlayerController`.