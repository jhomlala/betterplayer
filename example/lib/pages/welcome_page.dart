import 'dart:io';

import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/auto_fullscreen_orientation_page.dart';
import 'package:better_player_example/pages/basic_player_page.dart';
import 'package:better_player_example/pages/cache_page.dart';
import 'package:better_player_example/pages/clearkey_page.dart';
import 'package:better_player_example/pages/controller_controls_page.dart';
import 'package:better_player_example/pages/controls_always_visible_page.dart';
import 'package:better_player_example/pages/controls_configuration_page.dart';
import 'package:better_player_example/pages/custom_controls/change_player_theme_page.dart';
import 'package:better_player_example/pages/dash_page.dart';
import 'package:better_player_example/pages/drm_page.dart';
import 'package:better_player_example/pages/event_listener_page.dart';
import 'package:better_player_example/pages/fade_placeholder_page.dart';
import 'package:better_player_example/pages/hls_audio_page.dart';
import 'package:better_player_example/pages/hls_subtitles_page.dart';
import 'package:better_player_example/pages/hls_tracks_page.dart';
import 'package:better_player_example/pages/memory_player_page.dart';
import 'package:better_player_example/pages/normal_player_page.dart';
import 'package:better_player_example/pages/notification_player_page.dart';
import 'package:better_player_example/pages/overridden_aspect_ratio_page.dart';
import 'package:better_player_example/pages/overriden_duration_page.dart';
import 'package:better_player_example/pages/picture_in_picture_page.dart';
import 'package:better_player_example/pages/placeholder_until_play_page.dart';
import 'package:better_player_example/pages/playlist_page.dart';
import 'package:better_player_example/pages/resolutions_page.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_page.dart';
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
    _saveAssetEncryptVideoToFile();
    _saveLogoToFile();
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
      // TODO: add downloading
      _buildExampleElementWidget("Controls configuration", () {
        _navigateToPage(ControlsConfigurationPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Event listener", () {
        _navigateToPage(EventListenerPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Subtitles", () {
        _navigateToPage(SubtitlesPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Resolutions", () {
        _navigateToPage(ResolutionsPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("HLS subtitles", () {
        _navigateToPage(HlsSubtitlesPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("HLS tracks", () {
        _navigateToPage(HlsTracksPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("HLS Audio", () {
        _navigateToPage(HlsAudioPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Cache", () {
        _navigateToPage(CachePage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Playlist", () {
        _navigateToPage(PlaylistPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Video in list", () {
        _navigateToPage(VideoListPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Rotation and fit", () {
        _navigateToPage(RotationAndFitPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Memory player", () {
        _navigateToPage(MemoryPlayerPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Controller controls", () {
        _navigateToPage(ControllerControlsPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Auto fullscreen orientation", () {
        _navigateToPage(AutoFullscreenOrientationPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Overridden aspect ratio", () {
        _navigateToPage(OverriddenAspectRatioPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Notifications player", () {
        _navigateToPage(NotificationPlayerPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Reusable video list", () {
        _navigateToPage(ReusableVideoListPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Fade placeholder", () {
        _navigateToPage(FadePlaceholderPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Placeholder until play", () {
        _navigateToPage(PlaceholderUntilPlayPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Change player theme", () {
        _navigateToPage(ChangePlayerThemePage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Overridden duration", () {
        _navigateToPage(OverriddenDurationPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Picture in Picture", () {
        _navigateToPage(PictureInPicturePage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("Controls always visible", () {
        _navigateToPage(ControlsAlwaysVisiblePage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("DRM", () {
        _navigateToPage(DrmPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("ClearKey DRM", () {
        _navigateToPage(ClearKeyPage());
      }),
      // TODO: add downloading
      _buildExampleElementWidget("DASH", () {
        _navigateToPage(DashPage());
      }),
    ];
  }

  Widget _buildExampleElementWidget(String name, VoidCallback onClicked) {
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

  Future _saveAssetEncryptVideoToFile() async {
    var content =
        await rootBundle.load("assets/${Constants.fileTestVideoEncryptUrl}");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/${Constants.fileTestVideoEncryptUrl}");
    file.writeAsBytesSync(content.buffer.asUint8List());
  }

  ///Save logo to file, so we can use it later
  Future _saveLogoToFile() async {
    var content = await rootBundle.load("assets/${Constants.logo}");
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/${Constants.logo}");
    file.writeAsBytesSync(content.buffer.asUint8List());
  }
}
