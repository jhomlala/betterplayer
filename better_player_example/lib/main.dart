import 'dart:io';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/better_player_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BetterPlayerController betterPlayerController;
  List dataSourceList = List<BetterPlayerDataSource>();

  @override
  void initState() {
    super.initState();
  }

  Future<List<BetterPlayerDataSource>> setupData() async {
    await _saveAssetToFile();

    final directory = await getApplicationDocumentsDirectory();

    dataSourceList.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        subtitlesFile: File("${directory.path}/example_subtitles.srt")));

    dataSourceList.add(BetterPlayerDataSource(
        BetterPlayerDataSourceType.NETWORK,
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"));

    return dataSourceList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Better player example"),
      ),
      body: Container(child: _buildVideoPlayer()),
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder<List<BetterPlayerDataSource>>(
      future: setupData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Building!");
        } else {
          return AspectRatio(
            child: BetterPlaylist(
              betterPlayerSettings: const BetterPlayerSettings(
                  autoPlay: false, autoInitialize: true, allowFullScreen: true),
              betterPlayerPlaylistSettings:
              const BetterPlayerPlaylistSettings(),
              betterPlayerDataSourceList: snapshot.data,
            ),
            aspectRatio: 4 / 3,
          );
        }
      },
    );
  }

  void _onPlayerEvent(BetterPlayerEvent betterPlayerEvent) {
    print(
        "Player event: ${betterPlayerEvent
            .betterPlayerEventType} parameters: ${betterPlayerEvent
            .parameters}");
  }

  Future _saveAssetToFile() async {
    String content =
    await rootBundle.loadString("assets/example_subtitles.srt");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/example_subtitles.srt");
    file.writeAsString(content);
    print("File created $file");
  }
}
