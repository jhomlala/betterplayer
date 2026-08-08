import 'dart:io';

import 'package:example/constants.dart';
import 'package:example/pages/auto_fullscreen_orientation_page.dart';
import 'package:example/pages/basic_player_page.dart';
import 'package:example/pages/cache_page.dart';
import 'package:example/pages/clearkey_page.dart';
import 'package:example/pages/controller_controls_page.dart';
import 'package:example/pages/controls_always_visible_page.dart';
import 'package:example/pages/controls_configuration_page.dart';
import 'package:example/pages/custom_controls/change_player_theme_page.dart';
import 'package:example/pages/dash_page.dart';
import 'package:example/pages/drm_page.dart';
import 'package:example/pages/event_listener_page.dart';
import 'package:example/pages/fade_placeholder_page.dart';
import 'package:example/pages/hls_audio_page.dart';
import 'package:example/pages/hls_subtitles_page.dart';
import 'package:example/pages/hls_tracks_page.dart';
import 'package:example/pages/memory_player_page.dart';
import 'package:example/pages/normal_player_page.dart';
import 'package:example/pages/notification_player_page.dart';
import 'package:example/pages/overridden_aspect_ratio_page.dart';
import 'package:example/pages/overriden_duration_page.dart';
import 'package:example/pages/picture_in_picture_page.dart';
import 'package:example/pages/placeholder_until_play_page.dart';
import 'package:example/pages/playlist_page.dart';
import 'package:example/pages/resolutions_page.dart';
import 'package:example/pages/reusable_video_list/reusable_video_list_page.dart';
import 'package:example/pages/rotation_and_fit_page.dart';
import 'package:example/pages/subtitles_page.dart';
import 'package:example/pages/video_list/video_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

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
        title: const Text('Better Player Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Image.asset(
              'assets/logo.png',
              height: 200,
              width: 200,
            ),
            const Text(
              'Welcome to Better Player example app. Click on any element below to see example.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...buildExampleElementWidgets(),
          ],
        ),
      ),
    );
  }

  List<Widget> buildExampleElementWidgets() {
    return [
      _buildExampleElementWidget('Basic player', () {
        _navigateToPage(const BasicPlayerPage());
      }),
      _buildExampleElementWidget('Normal player', () {
        _navigateToPage(const NormalPlayerPage());
      }),
      _buildExampleElementWidget('Controls configuration', () {
        _navigateToPage(const ControlsConfigurationPage());
      }),
      _buildExampleElementWidget('Event listener', () {
        _navigateToPage(const EventListenerPage());
      }),
      _buildExampleElementWidget('Subtitles', () {
        _navigateToPage(const SubtitlesPage());
      }),
      _buildExampleElementWidget('Resolutions', () {
        _navigateToPage(const ResolutionsPage());
      }),
      _buildExampleElementWidget('HLS subtitles', () {
        _navigateToPage(const HlsSubtitlesPage());
      }),
      _buildExampleElementWidget('HLS tracks', () {
        _navigateToPage(const HlsTracksPage());
      }),
      _buildExampleElementWidget('HLS Audio', () {
        _navigateToPage(const HlsAudioPage());
      }),
      _buildExampleElementWidget('Cache', () {
        _navigateToPage(const CachePage());
      }),
      _buildExampleElementWidget('Playlist', () {
        _navigateToPage(const PlaylistPage());
      }),
      _buildExampleElementWidget('Video in list', () {
        _navigateToPage(const VideoListPage());
      }),
      _buildExampleElementWidget('Rotation and fit', () {
        _navigateToPage(const RotationAndFitPage());
      }),
      _buildExampleElementWidget('Memory player', () {
        _navigateToPage(const MemoryPlayerPage());
      }),
      _buildExampleElementWidget('Controller controls', () {
        _navigateToPage(const ControllerControlsPage());
      }),
      _buildExampleElementWidget('Auto fullscreen orientation', () {
        _navigateToPage(const AutoFullscreenOrientationPage());
      }),
      _buildExampleElementWidget('Overridden aspect ratio', () {
        _navigateToPage(const OverriddenAspectRatioPage());
      }),
      _buildExampleElementWidget('Notifications player', () {
        _navigateToPage(const NotificationPlayerPage());
      }),
      _buildExampleElementWidget('Reusable video list', () {
        _navigateToPage(const ReusableVideoListPage());
      }),
      _buildExampleElementWidget('Fade placeholder', () {
        _navigateToPage(const FadePlaceholderPage());
      }),
      _buildExampleElementWidget('Placeholder until play', () {
        _navigateToPage(const PlaceholderUntilPlayPage());
      }),
      _buildExampleElementWidget('Change player theme', () {
        _navigateToPage(const ChangePlayerThemePage());
      }),
      _buildExampleElementWidget('Overridden duration', () {
        _navigateToPage(const OverriddenDurationPage());
      }),
      _buildExampleElementWidget('Picture in Picture', () {
        _navigateToPage(const PictureInPicturePage());
      }),
      _buildExampleElementWidget('Controls always visible', () {
        _navigateToPage(const ControlsAlwaysVisiblePage());
      }),
      _buildExampleElementWidget('DRM', () {
        _navigateToPage(const DrmPage());
      }),
      _buildExampleElementWidget('ClearKey DRM', () {
        _navigateToPage(const ClearKeyPage());
      }),
      _buildExampleElementWidget('DASH', () {
        _navigateToPage(const DashPage());
      }),
    ];
  }

  Widget _buildExampleElementWidget(String name, Function onClicked) {
    return Material(
      child: InkWell(
        onTap: onClicked as void Function()?,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Divider(),
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
    final content = await rootBundle.loadString('assets/example_subtitles.srt');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/example_subtitles.srt');
    file.writeAsString(content);
  }

  ///Save video to file, so we can use it later
  Future _saveAssetVideoToFile() async {
    final content = await rootBundle.load('assets/testvideo.mp4');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/testvideo.mp4');
    file.writeAsBytesSync(content.buffer.asUint8List());
  }

  Future _saveAssetEncryptVideoToFile() async {
    final content =
        await rootBundle.load('assets/${Constants.fileTestVideoEncryptUrl}');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${Constants.fileTestVideoEncryptUrl}');
    file.writeAsBytesSync(content.buffer.asUint8List());
  }

  ///Save logo to file, so we can use it later
  Future _saveLogoToFile() async {
    final content = await rootBundle.load('assets/${Constants.logo}');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${Constants.logo}');
    file.writeAsBytesSync(content.buffer.asUint8List());
  }
}
