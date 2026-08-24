---
id: subtitlesconfiguration
title: Subtitles Configuration
---

# Subtitle Configuration

Better Player provides comprehensive support for subtitles, allowing you to load them from various sources and customize their appearance.

## Subtitle Sources

Subtitles can be loaded from **Network**, **File**, or **Memory** sources. You can also provide multiple subtitle tracks for a single video.

### Example: Network Subtitles
```dart
var dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "video_url",
    subtitles: BetterPlayerSubtitlesSource.single(
        type: BetterPlayerSubtitlesSourceType.network,
        url: "https://example.com/subtitles.srt"
    ),
);
```

### Example: Multiple Subtitle Tracks
```dart
var dataSource = BetterPlayerDataSource(
    BetterPlayerDataSourceType.network,
    "hls_url",
    subtitles: [
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          name: "English",
          urls: ["url_en"],
        ),
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          name: "German",
          urls: ["url_de"],
        ),
    ],
);
```

## Styling & Customization

The appearance of subtitles is controlled via `BetterPlayerSubtitlesConfiguration`.

```dart
var betterPlayerConfiguration = BetterPlayerConfiguration(
    subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
        fontSize: 20,
        fontColor: Colors.white,
        outlineEnabled: true,
        outlineColor: Colors.black,
        alignment: Alignment.bottomCenter,
    ),
);
```

### Parameters
*   **`fontSize`**, **`fontColor`**, **`fontFamily`**: Basic text styling.
*   **`outlineEnabled`**, **`outlineColor`**, **`outlineSize`**: Text border styling for better legibility.
*   **`leftPadding`**, **`rightPadding`**, **`bottomPadding`**: Adjust subtitle positioning.
*   **`alignment`**: The alignment of the subtitle text on the screen.
*   **`backgroundColor`**: The background color of the subtitle text box.
*   **`selectedByDefault`**: Whether to enable subtitles automatically.

## Accessing Current Subtitles
To retrieve the text of the currently displayed subtitle, use the `renderedSubtitle` property on the `BetterPlayerController`.
