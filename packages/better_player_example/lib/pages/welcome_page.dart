import 'package:better_player_example/constants.dart';
import 'package:better_player_example/model/example_item.dart';
import 'package:better_player_example/model/tab_destination.dart';
import 'package:better_player_example/pages/auto_fullscreen_on_rotation_example_page.dart';
import 'package:better_player_example/pages/auto_fullscreen_orientation_page.dart';
import 'package:better_player_example/pages/basic_player_page.dart';
import 'package:better_player_example/pages/better_player_feed_page.dart';
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
import 'package:better_player_example/pages/overridden_duration_page.dart';
import 'package:better_player_example/pages/picture_in_picture_page.dart';
import 'package:better_player_example/pages/placeholder_until_play_page.dart';
import 'package:better_player_example/pages/playlist_page.dart';
import 'package:better_player_example/pages/resolutions_page.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_page.dart';
import 'package:better_player_example/pages/rotation_and_fit_page.dart';
import 'package:better_player_example/pages/rtsp_page.dart';
import 'package:better_player_example/pages/subtitles_page.dart';
import 'package:better_player_example/utils/example_io_utils.dart';
import 'package:better_player_example/widgets/category_tab.dart';
import 'package:better_player_example/widgets/overview_tab.dart';
import 'package:better_player_example/widgets/welcome_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// Entry page presenting Better Player showcases organized by categories.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _saveAssetSubtitleToFile();
      _saveAssetVideoToFile();
      _saveAssetEncryptVideoToFile();
      _saveLogoToFile();
    }
  }

  void _onSelectTab(int index) {
    setState(() => _selectedTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 768;

        const destinations = [
          TabDestination(
            label: 'Overview',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          TabDestination(
            label: 'Core & UI',
            icon: Icons.play_circle_outline,
            selectedIcon: Icons.play_circle,
          ),
          TabDestination(
            label: 'Streaming',
            icon: Icons.stream_outlined,
            selectedIcon: Icons.stream,
          ),
          TabDestination(
            label: 'Advanced',
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
          ),
        ];

        final content = switch (_selectedTabIndex) {
          0 => OverviewTab(
            isWideScreen: isWideScreen,
            onNavigateToTab: _onSelectTab,
            coreItemsCount: _coreItems.length,
            streamingItemsCount: _streamingItems.length,
            advancedItemsCount: _advancedItems.length,
            featuredItems: [
              _coreItems[0],
              _streamingItems[2],
              _advancedItems[0],
              _streamingItems[6],
            ],
          ),
          1 => CategoryTab(
            title: 'Core & UI',
            description:
                'Basic and normal configurations, custom controls, and theme variations.',
            items: _coreItems,
            isWideScreen: isWideScreen,
          ),
          2 => CategoryTab(
            title: 'Streaming & Protocols',
            description:
                'Adaptive bitrates, HLS, DASH, DRM protection, tracks, and subtitles.',
            items: _streamingItems,
            isWideScreen: isWideScreen,
          ),
          _ => CategoryTab(
            title: 'Advanced & Feeds',
            description:
                'Playlists, video lists, memory loading, PiP, notifications, and caching.',
            items: _advancedItems,
            isWideScreen: isWideScreen,
          ),
        };

        if (isWideScreen) {
          return Scaffold(
            appBar: const WelcomeAppBar(),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: _onSelectTab,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ),
                  destinations: destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: const WelcomeAppBar(),
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: _onSelectTab,
            destinations: destinations
                .map(
                  (destination) => NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  static final List<ExampleItem> _coreItems = [
    ExampleItem(
      title: 'Basic player',
      description: 'Zero-configuration player with default controls.',
      icon: Icons.play_arrow,
      identifier: 'welcome_page_item_basic_player',
      pageBuilder: (_) => const BasicPlayerPage(),
    ),
    ExampleItem(
      title: 'Normal player',
      description:
          'Standard player setup with common options and listener hooks.',
      icon: Icons.play_circle_filled,
      identifier: 'welcome_page_item_normal_player',
      pageBuilder: (_) => const NormalPlayerPage(),
    ),
    ExampleItem(
      title: 'Controls configuration',
      description:
          'Customizing player colors, icons, seek buttons, and timers.',
      icon: Icons.settings,
      identifier: 'welcome_page_item_controls_configuration',
      pageBuilder: (_) => const ControlsConfigurationPage(),
    ),
    ExampleItem(
      title: 'Controls always visible',
      description: 'Lock controls to stay visible without auto-hide timeouts.',
      icon: Icons.visibility,
      identifier: 'welcome_page_item_controls_always_visible',
      pageBuilder: (_) => const ControlsAlwaysVisiblePage(),
    ),
    ExampleItem(
      title: 'Change player theme',
      description:
          'Switch between Cupertino, Material, and custom control themes.',
      icon: Icons.palette,
      identifier: 'welcome_page_item_change_player_theme',
      pageBuilder: (_) => const ChangePlayerThemePage(),
    ),
    ExampleItem(
      title: 'Controller controls',
      description:
          'External UI triggers driving playback via BetterPlayerController.',
      icon: Icons.tune,
      identifier: 'welcome_page_item_controller_controls',
      pageBuilder: (_) => const ControllerControlsPage(),
    ),
    ExampleItem(
      title: 'Fade placeholder',
      description:
          'Smooth fade transition between thumbnail and first video frame.',
      icon: Icons.animation,
      identifier: 'welcome_page_item_fade_placeholder',
      pageBuilder: (_) => const FadePlaceholderPage(),
    ),
    ExampleItem(
      title: 'Placeholder until play',
      description: 'Show cover poster image until playback explicitly starts.',
      icon: Icons.image,
      identifier: 'welcome_page_item_placeholder_until_play',
      pageBuilder: (_) => const PlaceholderUntilPlayPage(),
    ),
  ];

  static final List<ExampleItem> _streamingItems = [
    ExampleItem(
      title: 'Subtitles & WebVTT',
      description:
          'External SRT, WebVTT, and TTML subtitles with custom styling.',
      icon: Icons.subtitles,
      identifier: 'welcome_page_item_subtitles',
      pageBuilder: (_) => const SubtitlesPage(),
    ),
    ExampleItem(
      title: 'Resolutions',
      description:
          'Manual resolution switching for multi-bitrate network streams.',
      icon: Icons.high_quality,
      identifier: 'welcome_page_item_resolutions',
      pageBuilder: (_) => const ResolutionsPage(),
    ),
    ExampleItem(
      title: 'HLS tracks',
      description:
          'HLS adaptive bitrates with automatic and manual quality selection.',
      icon: Icons.auto_awesome_motion,
      identifier: 'welcome_page_item_hls_tracks',
      badgeText: 'HLS',
      pageBuilder: (_) => const HlsTracksPage(),
    ),
    ExampleItem(
      title: 'HLS subtitles',
      description:
          'Selecting in-manifest subtitle tracks provided by HLS stream.',
      icon: Icons.closed_caption,
      identifier: 'welcome_page_item_hls_subtitles',
      badgeText: 'HLS',
      pageBuilder: (_) => const HlsSubtitlesPage(),
    ),
    ExampleItem(
      title: 'HLS audio',
      description:
          'Alternate audio language track switching inside HLS manifest.',
      icon: Icons.audiotrack,
      identifier: 'welcome_page_item_hls_audio',
      badgeText: 'HLS',
      pageBuilder: (_) => const HlsAudioPage(),
    ),
    ExampleItem(
      title: 'DASH',
      description: 'Dynamic Adaptive Streaming over HTTP (MPD) playback.',
      icon: Icons.view_stream,
      identifier: 'welcome_page_item_dash',
      badgeText: 'DASH',
      supportedPlatforms: {
        TargetPlatform.android,
        TargetPlatform.windows,
        TargetPlatform.linux,
      },
      pageBuilder: (_) => const DashPage(),
    ),
    ExampleItem(
      title: 'DRM',
      description:
          'Encrypted streams with Widevine, FairPlay, and license servers.',
      icon: Icons.lock,
      identifier: 'welcome_page_item_drm',
      badgeText: 'DRM',
      supportedPlatforms: {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      },
      pageBuilder: (_) => const DrmPage(),
    ),
    ExampleItem(
      title: 'ClearKey DRM',
      description: 'ClearKey W3C encryption standard decryption workflow.',
      icon: Icons.key,
      identifier: 'welcome_page_item_clearkey_drm',
      badgeText: 'Android only',
      supportedPlatforms: {TargetPlatform.android},
      supportsWeb: false,
      pageBuilder: (_) => const ClearKeyPage(),
    ),
    ExampleItem(
      title: 'RTSP',
      description:
          'Real-Time Streaming Protocol playback for security cams and feeds.',
      icon: Icons.videocam,
      identifier: 'welcome_page_item_rtsp',
      badgeText: 'Android only',
      supportedPlatforms: {TargetPlatform.android},
      supportsWeb: false,
      pageBuilder: (_) => const RtspPage(),
    ),
  ];

  static final List<ExampleItem> _advancedItems = [
    ExampleItem(
      title: 'Playlist',
      description: 'Consecutive video sequence with next/previous controls.',
      icon: Icons.queue_music,
      identifier: 'welcome_page_item_playlist',
      pageBuilder: (_) => const PlaylistPage(),
    ),
    ExampleItem(
      title: 'Reusable video list',
      description:
          'High-performance scrolling feed recycling player controllers.',
      icon: Icons.dynamic_feed,
      identifier: 'welcome_page_item_reusable_video_list',
      pageBuilder: (_) => const ReusableVideoListPage(),
    ),
    ExampleItem(
      title: 'Video feed',
      description:
          'High-performance full-screen vertical video feed powered by BetterPlayerFeed and controller pooling.',
      icon: Icons.view_carousel,
      identifier: 'welcome_page_item_video_feed',
      pageBuilder: (_) => const BetterPlayerFeedPage(),
    ),
    ExampleItem(
      title: 'Cache',
      description:
          'Pre-caching and offline playback configuration for network videos.',
      icon: Icons.cached,
      identifier: 'welcome_page_item_cache',
      supportsWeb: false,
      pageBuilder: (_) => const CachePage(),
    ),
    ExampleItem(
      title: 'Event listener',
      description:
          'Subscribing to player events, buffering progress, and errors.',
      icon: Icons.notifications_active,
      identifier: 'welcome_page_item_event_listener',
      pageBuilder: (_) => const EventListenerPage(),
    ),
    ExampleItem(
      title: 'Memory player',
      description:
          'Playing video data directly loaded from in-memory byte arrays.',
      icon: Icons.memory,
      identifier: 'welcome_page_item_memory_player',
      pageBuilder: (_) => const MemoryPlayerPage(),
    ),
    ExampleItem(
      title: 'Picture in Picture',
      description:
          'Floating window background playback on supported platforms.',
      icon: Icons.picture_in_picture_alt,
      identifier: 'welcome_page_item_picture_in_picture',
      badgeText: 'PiP',
      supportedPlatforms: {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      },
      supportsWeb: false,
      pageBuilder: (_) => const PictureInPicturePage(),
    ),
    ExampleItem(
      title: 'Rotation and fit',
      description:
          'BoxFit scaling, player rotation angles, and aspect matching.',
      icon: Icons.crop_rotate,
      identifier: 'welcome_page_item_rotation_and_fit',
      pageBuilder: (_) => const RotationAndFitPage(),
    ),
    ExampleItem(
      title: 'Auto fullscreen orientation',
      description:
          'Locks orientation mode to landscape upon entering fullscreen.',
      icon: Icons.screen_lock_rotation,
      identifier: 'welcome_page_item_auto_fullscreen_orientation',
      badgeText: 'Mobile only',
      supportedPlatforms: {
        TargetPlatform.android,
        TargetPlatform.iOS,
      },
      supportsWeb: false,
      pageBuilder: (_) => const AutoFullscreenOrientationPage(),
    ),
    ExampleItem(
      title: 'Auto fullscreen on rotation',
      description:
          'Triggers fullscreen automatically when device rotates to landscape.',
      icon: Icons.screen_rotation,
      identifier: 'welcome_page_item_auto_fullscreen_on_rotation',
      badgeText: 'Mobile only',
      supportedPlatforms: {
        TargetPlatform.android,
        TargetPlatform.iOS,
      },
      supportsWeb: false,
      pageBuilder: (_) => const AutoFullscreenOnRotationExamplePage(),
    ),
    ExampleItem(
      title: 'Overridden aspect ratio',
      description:
          'Custom canvas aspect ratios independent of media dimensions.',
      icon: Icons.aspect_ratio,
      identifier: 'welcome_page_item_overridden_aspect_ratio',
      pageBuilder: (_) => const OverriddenAspectRatioPage(),
    ),
    ExampleItem(
      title: 'Overridden duration',
      description:
          'Custom total length presentation for continuous live streams.',
      icon: Icons.timelapse,
      identifier: 'welcome_page_item_overridden_duration',
      pageBuilder: (_) => const OverriddenDurationPage(),
    ),
    ExampleItem(
      title: 'Notifications player',
      description:
          'Lock screen background media playback controls and artwork.',
      icon: Icons.notification_important,
      identifier: 'welcome_page_item_notifications_player',
      badgeText: 'Mobile only',
      supportedPlatforms: {
        TargetPlatform.android,
        TargetPlatform.iOS,
      },
      supportsWeb: false,
      pageBuilder: (_) => const NotificationPlayerPage(),
    ),
  ];

  Future<void> _saveAssetSubtitleToFile() async {
    if (kIsWeb) return;
    try {
      final content = await rootBundle.loadString(
        'assets/example_subtitles.srt',
      );
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/example_subtitles.srt';
      await ExampleIoUtils.writeStringToFile(path: path, content: content);

      final vttContent = await rootBundle.loadString(
        'assets/example_subtitles.vtt',
      );
      final vttPath = '${directory.path}/example_subtitles.vtt';
      await ExampleIoUtils.writeStringToFile(
        path: vttPath,
        content: vttContent,
      );

      final ttmlContent = await rootBundle.loadString(
        'assets/example_subtitles.ttml',
      );
      final ttmlPath = '${directory.path}/example_subtitles.ttml';
      await ExampleIoUtils.writeStringToFile(
        path: ttmlPath,
        content: ttmlContent,
      );
    } catch (_) {}
  }

  Future<void> _saveAssetVideoToFile() async {
    if (kIsWeb) return;
    try {
      final content = await rootBundle.load('assets/testvideo.mp4');
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/testvideo.mp4';
      await ExampleIoUtils.writeBytesToFile(
        path: path,
        bytes: content.buffer.asUint8List(),
      );
    } catch (_) {}
  }

  Future<void> _saveAssetEncryptVideoToFile() async {
    if (kIsWeb) return;
    try {
      final content = await rootBundle.load('assets/testvideo_encrypt.mp4');
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/testvideo_encrypt.mp4';
      await ExampleIoUtils.writeBytesToFile(
        path: path,
        bytes: content.buffer.asUint8List(),
      );
    } catch (_) {}
  }

  Future<void> _saveLogoToFile() async {
    if (kIsWeb) return;
    try {
      final content = await rootBundle.load('assets/${Constants.logo}');
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${Constants.logo}';
      await ExampleIoUtils.writeBytesToFile(
        path: path,
        bytes: content.buffer.asUint8List(),
      );
    } catch (_) {}
  }
}
