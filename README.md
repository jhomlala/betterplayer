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
✔️ Refacored player controls  
✔️ Playlist support  
✔️ Video in ListView support  
✔️ Subtitles support  

**Known bugs:**  
- Can't run many video instances in app (this will be fixed in next video_player iteration)  

## Install

1. Add this to your **pubspec.yaml** file:

```yaml
dependencies:
  better_player: ^0.0.2
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

Then create BetterPlaylist:
```dart
@override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlaylist(
          betterPlayerSettings: BetterPlayerConfiguration(),
          betterPlayerPlaylistSettings: const BetterPlayerPlaylistSettings(),
          betterPlayerDataSourceList: dataSourceList),
    );
  }
```







