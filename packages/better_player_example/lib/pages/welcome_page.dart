import 'dart:io';

import 'package:better_player_example/constants.dart';
import 'package:better_player_example/pages/auto_fullscreen_on_rotation_example_page.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
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
      appBar: AppBar(title: const Text('Better Player Example')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            SvgPicture.asset('assets/logo.svg', height: 200, width: 200),
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
      _WelcomePageItem(
        name: 'Basic player',
        identifier: 'welcome_page_item_basic_player',
        onClicked: () => _navigateToPage(const BasicPlayerPage()),
      ),
      _WelcomePageItem(
        name: 'Normal player',
        identifier: 'welcome_page_item_normal_player',
        onClicked: () => _navigateToPage(const NormalPlayerPage()),
      ),
      _WelcomePageItem(
        name: 'Controls configuration',
        identifier: 'welcome_page_item_controls_configuration',
        onClicked: () => _navigateToPage(const ControlsConfigurationPage()),
      ),
      _WelcomePageItem(
        name: 'Event listener',
        identifier: 'welcome_page_item_event_listener',
        onClicked: () => _navigateToPage(const EventListenerPage()),
      ),
      _WelcomePageItem(
        name: 'Subtitles',
        identifier: 'welcome_page_item_subtitles',
        onClicked: () => _navigateToPage(const SubtitlesPage()),
      ),
      _WelcomePageItem(
        name: 'Resolutions',
        identifier: 'welcome_page_item_resolutions',
        onClicked: () => _navigateToPage(const ResolutionsPage()),
      ),
      _WelcomePageItem(
        name: 'HLS tracks',
        identifier: 'welcome_page_item_hls_tracks',
        onClicked: () => _navigateToPage(const HlsTracksPage()),
      ),
      _WelcomePageItem(
        name: 'HLS subtitles',
        identifier: 'welcome_page_item_hls_subtitles',
        onClicked: () => _navigateToPage(const HlsSubtitlesPage()),
      ),
      _WelcomePageItem(
        name: 'HLS Audio',
        identifier: 'welcome_page_item_hls_audio',
        onClicked: () => _navigateToPage(const HlsAudioPage()),
      ),
      _WelcomePageItem(
        name: 'Cache',
        identifier: 'welcome_page_item_cache',
        onClicked: () => _navigateToPage(const CachePage()),
      ),
      _WelcomePageItem(
        name: 'Playlist',
        identifier: 'welcome_page_item_playlist',
        onClicked: () => _navigateToPage(const PlaylistPage()),
      ),
      _WelcomePageItem(
        name: 'Video list',
        identifier: 'welcome_page_item_video_list',
        onClicked: () => _navigateToPage(const VideoListPage()),
      ),
      _WelcomePageItem(
        name: 'Rotation and fit',
        identifier: 'welcome_page_item_rotation_and_fit',
        onClicked: () => _navigateToPage(const RotationAndFitPage()),
      ),
      _WelcomePageItem(
        name: 'Memory player',
        identifier: 'welcome_page_item_memory_player',
        onClicked: () => _navigateToPage(const MemoryPlayerPage()),
      ),
      _WelcomePageItem(
        name: 'Controller controls',
        identifier: 'welcome_page_item_controller_controls',
        onClicked: () => _navigateToPage(const ControllerControlsPage()),
      ),
      _WelcomePageItem(
        name: 'Auto fullscreen orientation',
        identifier: 'welcome_page_item_auto_fullscreen_orientation',
        onClicked: () => _navigateToPage(const AutoFullscreenOrientationPage()),
      ),
      _WelcomePageItem(
        name: 'Auto fullscreen on rotation',
        identifier: 'welcome_page_item_auto_fullscreen_on_rotation',
        onClicked: () =>
            _navigateToPage(const AutoFullscreenOnRotationExamplePage()),
      ),
      _WelcomePageItem(
        name: 'Overridden aspect ratio',
        identifier: 'welcome_page_item_overridden_aspect_ratio',
        onClicked: () => _navigateToPage(const OverriddenAspectRatioPage()),
      ),
      _WelcomePageItem(
        name: 'Notifications player',
        identifier: 'welcome_page_item_notifications_player',
        onClicked: () => _navigateToPage(const NotificationPlayerPage()),
      ),
      _WelcomePageItem(
        name: 'Picture in Picture',
        identifier: 'welcome_page_item_picture_in_picture',
        onClicked: () => _navigateToPage(const PictureInPicturePage()),
      ),
      _WelcomePageItem(
        name: 'DRM',
        identifier: 'welcome_page_item_drm',
        onClicked: () => _navigateToPage(const DrmPage()),
      ),
      _WelcomePageItem(
        name: 'ClearKey DRM',
        identifier: 'welcome_page_item_clearkey_drm',
        onClicked: () => _navigateToPage(const ClearKeyPage()),
      ),
      _WelcomePageItem(
        name: 'Dash',
        identifier: 'welcome_page_item_dash',
        onClicked: () => _navigateToPage(const DashPage()),
      ),
      _WelcomePageItem(
        name: 'Reusable video list',
        identifier: 'welcome_page_item_reusable_video_list',
        onClicked: () => _navigateToPage(const ReusableVideoListPage()),
      ),
      _WelcomePageItem(
        name: 'Fade placeholder',
        identifier: 'welcome_page_item_fade_placeholder',
        onClicked: () => _navigateToPage(const FadePlaceholderPage()),
      ),
      _WelcomePageItem(
        name: 'Placeholder until play',
        identifier: 'welcome_page_item_placeholder_until_play',
        onClicked: () => _navigateToPage(const PlaceholderUntilPlayPage()),
      ),
      _WelcomePageItem(
        name: 'Change player theme',
        identifier: 'welcome_page_item_change_player_theme',
        onClicked: () => _navigateToPage(const ChangePlayerThemePage()),
      ),
      _WelcomePageItem(
        name: 'Overridden duration',
        identifier: 'welcome_page_item_overridden_duration',
        onClicked: () => _navigateToPage(const OverriddenDurationPage()),
      ),
      _WelcomePageItem(
        name: 'Controls always visible',
        identifier: 'welcome_page_item_controls_always_visible',
        onClicked: () => _navigateToPage(const ControlsAlwaysVisiblePage()),
      ),
    ];
  }

  Future _navigateToPage(Widget page) async {
    final route = MaterialPageRoute<void>(builder: (context) => page);
    await Navigator.push(context, route);
  }

  ///Save subtitles to file, so we can use it later
  Future _saveAssetSubtitleToFile() async {
    final content = await rootBundle.loadString('assets/example_subtitles.srt');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/example_subtitles.srt');
    await file.writeAsString(content);
  }

  ///Save video to file, so we can use it later
  Future _saveAssetVideoToFile() async {
    final content = await rootBundle.load('assets/testvideo.mp4');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/testvideo.mp4');
    await file.writeAsBytes(content.buffer.asUint8List());
  }

  ///Save video to file, so we can use it later
  Future _saveAssetEncryptVideoToFile() async {
    final content = await rootBundle.load('assets/testvideo_encrypt.mp4');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/testvideo_encrypt.mp4');
    await file.writeAsBytes(content.buffer.asUint8List());
  }

  ///Save logo to file, so we can use it later
  Future _saveLogoToFile() async {
    final content = await rootBundle.load('assets/${Constants.logo}');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${Constants.logo}');
    await file.writeAsBytes(content.buffer.asUint8List());
  }
}

class _WelcomePageItem extends StatelessWidget {
  const _WelcomePageItem({
    required this.name,
    required this.identifier,
    required this.onClicked,
  });

  final String name;
  final String identifier;
  final VoidCallback onClicked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      container: true,
      button: true,
      child: Material(
        child: InkWell(
          onTap: onClicked,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(name, style: const TextStyle(fontSize: 16)),
              ),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}
