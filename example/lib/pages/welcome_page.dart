import 'dart:io';

import 'package:better_player_example/pages/auto_fullscreen_orientation_page.dart';
import 'package:better_player_example/pages/basic_player_page.dart';
import 'package:better_player_example/pages/cache_page.dart';
import 'package:better_player_example/pages/controller_controls_page.dart';
import 'package:better_player_example/pages/controls_configuration_page.dart';
import 'package:better_player_example/pages/event_listener_page.dart';
import 'package:better_player_example/pages/hls_subtitles_page.dart';
import 'package:better_player_example/pages/hls_tracks_page.dart';
import 'package:better_player_example/pages/memory_player_page.dart';
import 'package:better_player_example/pages/normal_player_page.dart';
import 'package:better_player_example/pages/overridden_aspect_ratio_page.dart';
import 'package:better_player_example/pages/playlist_page.dart';
import 'package:better_player_example/pages/resolutions_page.dart';
import 'package:better_player_example/pages/rotation_and_fit_page.dart';
import 'package:better_player_example/pages/subtitles_page.dart';
import 'package:better_player_example/pages/video_list/video_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    _saveAssetSubtitleToFile();
    _saveAssetVideoToFile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Better Player Example"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Image.asset(
              "assets/logo.png",
              height: 200,
              width: 200,
            ),
            Text(
              "Welcome to Better Player example app. Click on any element below to see example.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...buildExampleElementWidgets()
          ],
        ),
      ),
    );
  }

  List<Widget> buildExampleElementWidgets() {
    return [
      _buildExampleElementWidget("Basic player", () {
        _navigateToPage(BasicPlayerPage());
      }),
      _buildExampleElementWidget("Normal player", () {
        _navigateToPage(NormalPlayerPage());
      }),
      _buildExampleElementWidget("Controls configuration", () {
        _navigateToPage(ControlsConfigurationPage());
      }),
      _buildExampleElementWidget("Event listener", () {
        _navigateToPage(EventListenerPage());
      }),
      _buildExampleElementWidget("Subtitles", () {
        _navigateToPage(SubtitlesPage());
      }),
      _buildExampleElementWidget("Resolutions", () {
        _navigateToPage(ResolutionsPage());
      }),
      _buildExampleElementWidget("HLS subtitles", () {
        _navigateToPage(HlsSubtitlesPage());
      }),
      _buildExampleElementWidget("HLS tracks", () {
        _navigateToPage(HlsTracksPage());
      }),
      _buildExampleElementWidget("Cache", () {
        _navigateToPage(CachePage());
      }),
      _buildExampleElementWidget("Playlist", () {
        _navigateToPage(PlaylistPage());
      }),
      _buildExampleElementWidget("Video in list", () {
        _navigateToPage(VideoListPage());
      }),
      _buildExampleElementWidget("Rotation and fit", () {
        _navigateToPage(RotationAndFitPage());
      }),
      _buildExampleElementWidget("Memory player", () {
        _navigateToPage(MemoryPlayerPage());
      }),
      _buildExampleElementWidget("Controller controls page", () {
        _navigateToPage(ControllerControlsPage());
      }),
      _buildExampleElementWidget("Auto fullscreen orientation page", () {
        _navigateToPage(AutoFullscreenOrientationPage());
      }),
      _buildExampleElementWidget("Overridden aspect ratio page", () {
        _navigateToPage(OverriddenAspectRatioPage());
      }),
    ];
  }

  Widget _buildExampleElementWidget(String name, Function onClicked) {
    return Material(
      child: InkWell(
        onTap: onClicked,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                name,
                style: TextStyle(fontSize: 16),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }

  Future _navigateToPage(Widget routeWidget) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => routeWidget),
    );
  }

  ///Save subtitles to file, so we can use it later
  Future _saveAssetSubtitleToFile() async {
    String content =
        await rootBundle.loadString("assets/example_subtitles.srt");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/example_subtitles.srt");
    file.writeAsString(content);
  }

  ///Save video to file, so we can use it later
  Future _saveAssetVideoToFile() async {
    var content = await rootBundle.load("assets/testvideo.mp4");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/testvideo.mp4");
    file.writeAsBytesSync(content.buffer.asUint8List());
  }
}
