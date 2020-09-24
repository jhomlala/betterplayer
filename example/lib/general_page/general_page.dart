import 'dart:async';
import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/other_page/other_page.dart';
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
    var dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.NETWORK,
      "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
      liveStream: true,
      subtitles: BetterPlayerSubtitlesSource(
        type: BetterPlayerSubtitlesSourceType.NETWORK,
        url:
            "https://dl.dropboxusercontent.com/s/71nzjo2ux3evxqk/example_subtitles.srt",
      ),
    );
    _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
            controlsConfiguration: BetterPlayerControlsConfiguration(
          enableProgressText: true,
          enablePlaybackSpeed: true,
        )),
        betterPlayerDataSource: dataSource);
    _betterPlayerController.addEventsListener((event) {
      print("Better player event: ${event.betterPlayerEventType}");
    });
    return _betterPlayerController;
  }

  Future<BetterPlayerController> setupFileVideoData() async {
    await _saveAssetVideoToFile();
    await _saveAssetSubtitleToFile();
    final directory = await getApplicationDocumentsDirectory();

    var dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.FILE, "${directory.path}/testvideo.mp4",
        subtitles: BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.FILE,
          url: "${directory.path}/example_subtitles.srt",
        ));
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(),
      betterPlayerDataSource: dataSource,
    );

    return _betterPlayerController;
  }

  Future _saveAssetSubtitleToFile() async {
    String content =
        await rootBundle.loadString("assets/example_subtitles.srt");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/example_subtitles.srt");
    file.writeAsString(content);
  }

  Future _saveAssetVideoToFile() async {
    var content = await rootBundle.load("assets/testvideo.mp4");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/testvideo.mp4");
    file.writeAsBytesSync(content.buffer.asUint8List());
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
      _buildShowFileVideoButton(),
      _buildOtherPageButton(),
    ]);
  }

  Widget _buildDefaultVideo() {
    return FutureBuilder<BetterPlayerController>(
      future: _setupDefaultVideoData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
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
  }

  Widget _buildShowFileVideoButton() {
    return Column(children: [
      RaisedButton(
        child: Text("Show video from file"),
        onPressed: () {
          _fileVideoShown = !_fileVideoShown;
          _fileVideoStreamController.add(_fileVideoShown);
        },
      ),
      _buildFileVideo()
    ]);
  }

  Widget _buildOtherPageButton() {
    return Column(children: [
      RaisedButton(
        child: Text("Show video in other page"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OtherPage()),
          );
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
