import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class GeneralPage extends StatefulWidget {
  @override
  _GeneralPageState createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {
  BetterPlayerController _betterPlayerController;
  StreamController<bool> _fileVideoStreamController =
      StreamController.broadcast();
  bool _fileVideoShown = false;

  Future<BetterPlayerController> _setupDefaultVideoData() async {
    await _saveAssetSubtitleToFile();
    print("File created");

    //final directory = await getApplicationDocumentsDirectory();
    print("Building data source");
    var dataSource = BetterPlayerDataSource(BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        //subtitlesUrl: "${directory.path}/example_subtitles.srt");
        subtitles: BetterPlayerSubtitlesSource(
            type: BetterPlayerSubtitlesSourceType.NETWORK,
            url:
                "https://dl.dropboxusercontent.com/s/71nzjo2ux3evxqk/example_subtitles.srt"));
    print("building controller");
    _betterPlayerController = BetterPlayerController(BetterPlayerSettings(),
        betterPlayerDataSource: dataSource);
    print("Created controller");
    return _betterPlayerController;
  }

  Future<BetterPlayerController> setupFileVideoData() async {
    await _saveAssetVideoToFile();
    final directory = await getApplicationDocumentsDirectory();

    var dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.FILE, "${directory.path}/testvideo.mp4");
    _betterPlayerController = BetterPlayerController(BetterPlayerSettings(),
        betterPlayerDataSource: dataSource);
    return _betterPlayerController;
  }

  Future _saveAssetSubtitleToFile() async {
    String content =
        await rootBundle.loadString("assets/example_subtitles.srt");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/example_subtitles.srt");
    file.writeAsString(content);
    print("File created $file");
  }

  Future _saveAssetVideoToFile() async {
    String content = await rootBundle.loadString("assets/testvideo.mp4");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/textvideo.mp4");
    file.writeAsString(content);
    print("File created $file");
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Padding(
        padding: EdgeInsets.all(8),
        child: Text("This is example default video. This video is loaded from"
            " URL. Subtitles are loaded from file."),
      ),
      _buildDefaultVideo(),
      _buildShowFileVideoButton()
    ]);
  }

  Widget _buildDefaultVideo() {
    return FutureBuilder<BetterPlayerController>(
      future: _setupDefaultVideoData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        } else {
          print("Go!");
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(
              controller: snapshot.data,
            ),
          );
        }
      },
    );
  }

  Widget _buildShowFileVideoButton() {
    return Column(children: [
      RaisedButton(
        child: Text("Show file video"),
        onPressed: () {
          _fileVideoShown = !_fileVideoShown;
          _fileVideoStreamController.add(_fileVideoShown);
        },
      ),
      _buildFileVideo()
    ]);
  }

  Widget _buildFileVideo() {
    return StreamBuilder<bool>(
      stream: _fileVideoStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot?.data == true) {
          return FutureBuilder<BetterPlayerController>(
            future: _setupDefaultVideoData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              } else {
                return AspectRatio(
                  aspectRatio: 16 / 9,
                  child: BetterPlayer(
                    controller: snapshot.data,
                  ),
                );
              }
            },
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  @override
  void dispose() {
    _fileVideoStreamController.close();
    super.dispose();
  }
}
