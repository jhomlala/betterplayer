<p align="center">
<img src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/logo.png">
</p>

# Better Player

[![pub package](https://img.shields.io/pub/v/better_player.svg)](https://pub.dartlang.org/packages/better_player)
[![pub package](https://img.shields.io/github/license/jhomlala/betterplayer.svg?style=flat)](https://github.com/jhomlala/betterplayer)
[![pub package](https://img.shields.io/badge/platform-flutter-blue.svg)](https://github.com/jhomlala/betterplayer)

Advanced video player based on video_player and Chewie. It's solves many typical use cases and it's easy to run.

## Introduction
This plugin is based on [Chewie](https://github.com/brianegan/chewie). Chewie is awesome plugin and works well in many cases. Better Player is a continuation of ideas introduced in Chewie. Better player fix common bugs, adds more configuration options and solves typical use cases. 

**Features:**  
✔️ Fixed common bugs  
✔️ Added advanced configuration options  
✔️ Refactored player controls  
✔️ Playlist support  
✔️ Video in ListView support  
✔️ Subtitles support: (formats: SRT, WEBVTT with HTML tags support; subtitles from HLS)  
✔️ HTTP Headers support  
✔️ BoxFit of video support  
✔️ Playback speed support



## Install

1. Add this to your **pubspec.yaml** file:

```yaml
dependencies:
  better_player: ^0.0.19
```

2. Install it

```bash
$ flutter packages get
```

3. Import it

```dart
import 'package:better_player/better_player.dart';
```

## Usage
Check [Example project](https://github.com/jhomlala/betterplayer/tree/master/example).

### Basic usage

Create BetterPlayerDataSource and BetterPlayerController. You should do it in initState:
```dart
BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4");
    _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(),
        betterPlayerDataSource: betterPlayerDataSource);
  }
````

Create BetterPlayer widget wrapped in AspectRatio widget:
```dart
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(
        controller: _betterPlayerController,
      ),
    );
  }
```

### Playlist
To use playlist, you need to create dataset with multiple videos:
```dart
  List<BetterPlayerDataSource> createDataSet() {
    List dataSourceList = List<BetterPlayerDataSource>();
    dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      ),
    );
    dataSourceList.add(
      BetterPlayerDataSource(BetterPlayerDataSourceType.NETWORK,
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
    );
    dataSourceList.add(
      BetterPlayerDataSource(BetterPlayerDataSourceType.NETWORK,
          "http://sample.vodobox.com/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8"),
    );
    return dataSourceList;
  }
```

Then create BetterPlayerPlaylist:
```dart
@override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayerPlaylist(
          betterPlayerConfiguration: BetterPlayerConfiguration(),
          betterPlayerPlaylistConfiguration: const BetterPlayerPlaylistConfiguration(),
          betterPlayerDataSourceList: dataSourceList),
    );
  }
```

### BetterPlayerListViewPlayer
BetterPlayerListViewPlayer will auto play/pause video once video is visible on screen with playFraction. PlayFraction describes percent of video that must be visibile to play video. If playFraction is 0.8 then 80% of video height must be visible on screen to auto play video

```dart
 @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayerListVideoPlayer(
        BetterPlayerDataSource(
            BetterPlayerDataSourceType.NETWORK, videoListData.videoUrl),
        key: Key(videoListData.hashCode.toString()),
        playFraction: 0.8,
      ),
    );
  }
```

You can control BetterPlayerListViewPlayer with BetterPlayerListViewPlayerController. You need to pass
BetterPlayerListViewPlayerController to BetterPlayerListVideoPlayer. See more here:
https://github.com/jhomlala/betterplayer/blob/master/example/lib/video_list/video_list_widget.dart

### Subtitles
Subtitles can be configured from 3 different sources: file, network and memory. Subtitles source is passed in BetterPlayerDataSource:

Network subtitles:
```dart
    var dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.NETWORK,
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      subtitles: BetterPlayerSubtitlesSource.single(
          type: BetterPlayerSubtitlesSourceType.NETWORK,
          url:
              "https://dl.dropboxusercontent.com/s/71nzjo2ux3evxqk/example_subtitles.srt"),
    );
```

File subtitles:
```dart
 var dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.FILE,
      "${directory.path}/testvideo.mp4",
      subtitles: BetterPlayerSubtitlesSource.single(
        type: BetterPlayerSubtitlesSourceType.FILE,
        url: "${directory.path}/example_subtitles.srt",
      ),
    );
```
### BetterPlayerConfiguration
You can provide configuration to your player when creating BetterPlayerController.

```dart
    var betterPlayerConfiguration = BetterPlayerConfiguration(
      autoPlay: true,
      looping: true,
      fullScreenByDefault: true,
    );
```

Possible configuration options:
```dart
    /// Play the video as soon as it's displayed
    final bool autoPlay;

    /// Start video at a certain position
    final Duration startAt;

    /// Whether or not the video should loop
    final bool looping;

    /// Weather or not to show the controls when initializing the widget.
    final bool showControlsOnInitialize;

    /// When the video playback runs  into an error, you can build a custom
    /// error message.
    final Widget Function(BuildContext context, String errorMessage) errorBuilder;

    /// The Aspect Ratio of the Video. Important to get the correct size of the
    /// video!
    ///
    /// Will fallback to fitting within the space allowed.
    final double aspectRatio;

    /// The placeholder is displayed underneath the Video before it is initialized
    /// or played.
    final Widget placeholder;

    /// A widget which is placed between the video and the controls
    final Widget overlay;

    /// Defines if the player will start in fullscreen when play is pressed
    final bool fullScreenByDefault;

    /// Defines if the player will sleep in fullscreen or not
    final bool allowedScreenSleep;


    /// Defines the system overlays visible after exiting fullscreen
    final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

    /// Defines the set of allowed device orientations after exiting fullscreen
    final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

    /// Defines a custom RoutePageBuilder for the fullscreen
    final BetterPlayerRoutePageBuilder routePageBuilder;

    /// Defines a event listener where video player events will be send
    final Function(BetterPlayerEvent) eventListener;

    ///Defines subtitles configuration
    final BetterPlayerSubtitlesConfiguration subtitlesConfiguration;

    ///Defines controls configuration
    final BetterPlayerControlsConfiguration controlsConfiguration;

    ///Defines fit of the video, allows to fix video stretching, see possible
    ///values here: https://api.flutter.dev/flutter/painting/BoxFit-class.html
    final BoxFit fit;

    ///Defines rotation of the video in degrees. Default value is 0. Can be 0, 90, 180, 270.
    ///Angle will rotate only video box, controls will be in the same place.
    final double rotation;
```

### BetterPlayerSubtitlesConfiguration
You can provide subtitles configuration with this class. You should put BetterPlayerSubtitlesConfiguration in BetterPlayerConfiguration.
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
```

### BetterPlayerControlsConfiguration
Configuration for player GUI. You should pass this configuration to BetterPlayerConfiguration.

```dart
ar betterPlayerConfiguration = BetterPlayerConfiguration(
      controlsConfiguration: BetterPlayerControlsConfiguration(
        textColor: Colors.black,
        iconsColor: Colors.black,
      ),
    );
```

Possible configuration options:
```dart
  ///Color of the control bars
  final Color controlBarColor;

  ///Color of texts
  final Color textColor;

  ///Color of icons
  final Color iconsColor;

  ///Icon of play
  final IconData playIcon;

  ///Icon of pause
  final IconData pauseIcon;

  ///Icon of mute
  final IconData muteIcon;

  ///Icon of unmute
  final IconData unMuteIcon;

  ///Icon of fullscreen mode enable
  final IconData fullscreenEnableIcon;

  ///Icon of fullscreen mode disable
  final IconData fullscreenDisableIcon;

  ///Cupertino only icon, icon of skip
  final IconData skipBackIcon;

  ///Cupertino only icon, icon of forward
  final IconData skipForwardIcon;

  ///Flag used to enable/disable fullscreen
  final bool enableFullscreen;

  ///Flag used to enable/disable mute
  final bool enableMute;

  ///Flag used to enable/disable progress texts
  final bool enableProgressText;

  ///Flag used to enable/disable progress bar
  final bool enableProgressBar;

  ///Flag used to enable/disable play-pause
  final bool enablePlayPause;

  ///Progress bar played color
  final Color progressBarPlayedColor;

  ///Progress bar circle color
  final Color progressBarHandleColor;

  ///Progress bar buffered video color
  final Color progressBarBufferedColor;

  ///Progress bar background color
  final Color progressBarBackgroundColor;

  ///Time to hide controls
  final Duration controlsHideTime;

  ///Custom controls, it will override Material/Cupertino controls
  final Widget customControls;

  ///Flag used to show/hide controls
  final bool showControls;

  ///Flag used to show controls on init
  final bool showControlsOnInitialize;

  ///Control bar height
  final double controlBarHeight;

  ///Default error widget text
  final String defaultErrorText;

  ///Default loading next video text
  final String loadingNextVideoText;

  ///Text displayed when asset displayed in player is live stream
  final String liveText;

  ///Live text color;
  final Color liveTextColor;

  ///Flag used to show/hide playback speed
  final bool enablePlaybackSpeed;
```

### BetterPlayerPlaylistConfiguration
Configure your playlist. Pass this object to BetterPlayerPlaylist

```dart
 var betterPlayerPlaylistConfiguration = BetterPlayerPlaylistConfiguration(
      loopVideos: false,
      nextVideoDelay: Duration(milliseconds: 5000),
    );
```

Possible configuration options:
```dart
  ///How long user should wait for next video
  final Duration nextVideoDelay;

  ///Should videos be looped
  final bool loopVideos;
```

### BetterPlayerDataSource
Define source for one video in your app.
```dart
    var dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.NETWORK,
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      subtitles: BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.FILE,
        url: "${directory.path}/example_subtitles.srt",
      ),
      headers: {"header":"my_custom_header"}
    );
```

Possible configuration options:
```
  ///Type of source of video
  final BetterPlayerDataSourceType type;

  ///Url of the video
  final String url;

  ///Subtitles configuration
  final BetterPlayerSubtitlesSource subtitles;

  ///Flag to determine if current data source is live stream
  final bool liveStream;

  /// Custom headers for player
  final Map<String, String> headers;

  ///Should player use hls subtitles. Default is true.
  final bool useHlsSubtitles;
```


### BetterPlayerSubtitlesSource
Define source of subtitles in your video:
```dart
 var subtitles = BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.FILE,
        url: "${directory.path}/example_subtitles.srt",
      );
```

Possible configuration options:
```dart
  ///Source type
  final BetterPlayerSubtitlesSourceType type;

  ///Url of the subtitles, used with file or network subtitles
  final String url;

  ///Content of subtitles, used when type is memory
  final String content;
```

### Listen to video events
You can listen to video player events like:
```dart
  PLAY,
  PAUSE,
  SEEK_TO,
  OPEN_FULLSCREEN,
  HIDE_FULLSCREEN,
  SET_VOLUME,
  PROGRESS,
  FINISHED,
  EXCEPTION,
  SET_SPEED,
  CHANGE_SUBTITLES
```

After creating BetterPlayerController you can add event listener this way:
```dart
 _betterPlayerController.addEventsListener((event){
      print("Better player event: ${event.betterPlayerEventType}");
    });
```
Your event listener will ne auto-disposed on dispose time :)


### More documentation
https://pub.dev/documentation/better_player/latest/better_player/better_player-library.html







