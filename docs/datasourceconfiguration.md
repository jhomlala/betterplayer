## Data source configuration 
Define source for one video in your app with `BetterPlayerDataSource`. 

There are 3 types of data sources:
* Network - data source which uses url to play video from external resources
* File - data source which uses url to play video from internal resources
* Memory - data source which uses list of bytes to play video from memory
```dart
    var dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      subtitles: BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.file,
        url: "${directory.path}/example_subtitles.srt",
      ),
      headers: {"header":"my_custom_header"}
    );
```

You can use type specific factories to build your data source.
Use `BetterPlayerDataSource.network` to build network data source, `BetterPlayerDataSource.file` to build file data source and `BetterPlayerDataSource.memory` to build memory data source.

Possible configuration options:
```dart
///Type of source of video
final BetterPlayerDataSourceType type;

///Url of the video
final String url;

///Subtitles configuration
///You can pass here multiple subtitles
final List<BetterPlayerSubtitlesSource> subtitles;

///Flag to determine if current data source is live stream
final bool liveStream;

/// Custom headers for player
final Map<String, String> headers;

///Should player use hls / dash subtitles (ASMS - Adaptive Streaming Media Sources).
final bool useAsmsSubtitles;

///Should player use hls / dash tracks
final bool useAsmsTracks;

///Should player use hls / dash audio tracks
final bool useAsmsAudioTracks;

///List of strings that represents tracks names.
///If empty, then better player will choose name based on track parameters
final List<String> hlsTrackNames;

///Optional, alternative resolutions for non-hls video. Used to setup
///different qualities for video.
///Data should be in given format:
///{"360p": "url", "540p": "url2" }
final Map<String, String> resolutions;

///Optional cache configuration, used only for network data sources
final BetterPlayerCacheConfiguration cacheConfiguration;

///List of bytes, used only in memory player
final List<int> bytes;

///Configuration of remote controls notification
final BetterPlayerNotificationConfiguration notificationConfiguration;

///Duration which will be returned instead of original duration
final Duration overriddenDuration;

///Video format hint when data source url has not valid extension.
final BetterPlayerVideoFormat videoFormat;

///Extension of video without dot. Used only in memory data source.
final String videoExtension;

///Configuration of content protection
final BetterPlayerDrmConfiguration drmConfiguration;

///Placeholder widget which will be shown until video load or play. This
///placeholder may be useful if you want to show placeholder before each video
///in playlist. Otherwise, you should use placeholder from
/// BetterPlayerConfiguration.
final Widget placeholder;
```