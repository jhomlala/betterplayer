---
id: resolutions_of_video
title: Video Resolutions
---

# Video Resolutions

For standard video formats (non-HLS, non-DASH), you can provide multiple URLs corresponding to different quality levels (e.g., 720p, 1080p). This allows users to manually select their preferred resolution.

## Implementation Example

```dart
var dataSource = PlayerDataSource(
    DataSourceType.network,
    "https://example.com/video_720p.mp4",
    resolutions: {
        "360p": "https://example.com/video_360p.mp4",
        "720p": "https://example.com/video_720p.mp4",
        "1080p": "https://example.com/video_1080p.mp4",
    },
);
```

:::note
For adaptive streaming formats like HLS and DASH, Better Player automatically detects and handles resolution switching based on the manifest file.
:::
