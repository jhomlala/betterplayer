## Example project
Check [Example project](https://github.com/jhomlala/betterplayer/tree/master/example) which shows how to use Better Player in different scenarios.

### Basic usage
There are 2 basic methods which you can use to setup Better Player:
```dart
BetterPlayer.network(url, configuration)
BetterPlayer.file(url, configuration)
```
There methods setup basic configuration for you and allows you to start using player in few seconds.
Here is an example:
```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Example player"),
      ),
      body: AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer.network(
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
          betterPlayerConfiguration: BetterPlayerConfiguration(
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }
```
In this example, we're just showing video from url with aspect ratio = 16/9.
Better Player has many more configuration options which are described in next pages.


### Normal usage
When you want have more configuration options then you need to create `BetterPlayerDataSource` and `BetterPlayerController`. `BetterPlayerDataSource` describes
source of your video. With `BetterPlayerDataSource` you will provide all important informations like url of video, type of video, subtitles source and more.
`BetterPlayerController` is a Flutter convention to have a manager class to control instance of video widget. With `BetterPlayerController` you will be able to
change behavior of the video widget, for example start or stop video, change volume and more.


Create `BetterPlayerDataSource` and `BetterPlayerController`. You should do it in initState of your widget:
```dart
BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    super.initState();
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4");
    _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(),
        betterPlayerDataSource: betterPlayerDataSource);
  }
````

Create `BetterPlayer` widget wrapped in `AspectRatio` widget:
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