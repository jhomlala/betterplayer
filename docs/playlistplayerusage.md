## Playlist player usage
Playlist is a one of the Better Player widgets which allows to configure list of videos which will be played one after another.
Once video finishes, there's interval time (customizable) after which next video will be played. This interval time is displayed in
player UI and it's skippable.

To use playlist, you need to create dataset with multiple videos:
```dart
  List<BetterPlayerDataSource> createDataSet() {
    List dataSourceList = List<BetterPlayerDataSource>();
    dataSourceList.add(
      BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      ),
    );
    dataSourceList.add(
      BetterPlayerDataSource(BetterPlayerDataSourceType.network,
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
    );
    dataSourceList.add(
      BetterPlayerDataSource(BetterPlayerDataSourceType.network,
          "http://sample.vodobox.com/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8"),
    );
    return dataSourceList;
  }
```

Then create `BetterPlayerPlaylist` widget:
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
