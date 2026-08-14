
## Resolutions of the video
You can setup video with different resolutions. Use resolutions parameter in data source. This should be used
only for normal videos (non-hls, non-dash) to setup different qualities of the original video.

```dart
var dataSource = BetterPlayerDataSource(BetterPlayerDataSourceType.network,
    "https://file-examples-com.github.io/uploads/2017/04/file_example_MP4_480_1_5MG.mp4",
    resolutions: {
        "LOW":
            "https://file-examples-com.github.io/uploads/2017/04/file_example_MP4_480_1_5MG.mp4",
        "MEDIUM":
            "https://file-examples-com.github.io/uploads/2017/04/file_example_MP4_640_3MG.mp4",
        "LARGE":
            "https://file-examples-com.github.io/uploads/2017/04/file_example_MP4_1280_10MG.mp4",
        "EXTRA_LARGE":
            "https://file-examples-com.github.io/uploads/2017/04/file_example_MP4_1920_18MG.mp4"
    });
```