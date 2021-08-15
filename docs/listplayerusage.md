## List player usage

`BetterPlayerListViewPlayer` is one of the Better Player which has special function: to help displaying videos in list.

`BetterPlayerListViewPlayer` will auto play/pause video once video is visible on screen with `playFraction`. `playFraction` describes percent of video that must be visibile to play video. If playFraction is 0.8 then 80% of video height must be visible on screen to automatically play the video.

```dart
 @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayerListVideoPlayer(
        BetterPlayerDataSource(
            BetterPlayerDataSourceType.network, videoListData.videoUrl),
        key: Key(videoListData.hashCode.toString()),
        playFraction: 0.8,
      ),
    );
  }
```

You can control `BetterPlayerListViewPlayer` with `BetterPlayerListViewPlayerController`. You need to pass `BetterPlayerListViewPlayerController` to `BetterPlayerListVideoPlayer`. See more in example app.

`BetterPlayerListViewPlayer` is good solution if you know that your list will be not too long. If you know that your list of videos will be long then you need to recycle `BetterPlayerController` instances. This is required because each creation of `BetterPlayerController` requires a lot of resources of the device. You need to remember that there are some devices which allows to create 2-3 instances of `BetterPlayerController` due to low hardware specification. To handle problem like this, you should use **recycle/reusable** techniques, where you will create 2-3 instances of `BetterPlayerController` and simply reuse them in list cell. See reusable video list example here: https://github.com/jhomlala/betterplayer/tree/master/example/lib/pages/reusable_video_list

To resolve random OOM issues, try to lower values in `bufferingConfiguration` in `BetterPlayerDataSource`.