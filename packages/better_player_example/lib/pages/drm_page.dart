import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class DrmPage extends StatefulWidget {
  const DrmPage({super.key});

  @override
  _DrmPageState createState() => _DrmPageState();
}

class _DrmPageState extends State<DrmPage> {
  BetterPlayerController? _tokenController;
  BetterPlayerController? _widevineController;
  BetterPlayerController? _fairplayController;

  bool get _isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool get _supportsWidevine => !_isWindows && !_isApple;
  bool get _supportsFairplay => _isApple;

  @override
  void initState() {
    super.initState();
    const configuration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );

    if (_supportsWidevine) {
      _tokenController = BetterPlayerController(configuration);
      _tokenController!.setupDataSource(
        PlayerDataSource(
          DataSourceType.network,
          Constants.tokenEncodedHlsUrl,
          videoFormat: VideoFormat.dash,
          drmConfiguration: DrmConfiguration(
            drmType: DrmType.widevine,
            licenseUrl:
                'https://drm-widevine-licensing.axtest.net/AcquireLicense',
            headers: {'X-AxDRM-Message': Constants.tokenEncodedHlsToken},
          ),
        ),
      );

      _widevineController = BetterPlayerController(configuration);
      _widevineController!.setupDataSource(
        PlayerDataSource(
          DataSourceType.network,
          Constants.widevineVideoUrl,
          drmConfiguration: DrmConfiguration(
            drmType: DrmType.widevine,
            licenseUrl: Constants.widevineLicenseUrl,
            headers: {'Test': 'Test2'},
          ),
        ),
      );
    }

    if (_supportsFairplay) {
      _fairplayController = BetterPlayerController(configuration);
      _fairplayController!.setupDataSource(
        PlayerDataSource(
          DataSourceType.network,
          Constants.fairplayHlsUrl,
          drmConfiguration: DrmConfiguration(
            drmType: DrmType.fairplay,
            certificateUrl: Constants.fairplayCertificateUrl,
            licenseUrl: Constants.fairplayLicenseUrl,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tokenController?.dispose();
    _widevineController?.dispose();
    _fairplayController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('DRM Protected Playback')),
      body: DemoContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Hardware & Software DRM',
                description:
                    'Covers Widevine modular decryption (Android / Web) and '
                    'FairPlay Streaming decryption (iOS / macOS).',
                instructions:
                    'Playback depends on platform DRM licensing capabilities.',
                icon: Icons.security_outlined,
              ),
              if (_isWindows) ...[
                const PlatformNoteCard(
                  title: 'DRM Unavailable on Windows',
                  message:
                      'The Windows backend (mpv) does not bundle DRM Content Decryption '
                      'Modules. DRM streams are supported on Android, iOS, macOS, and Web.',
                  icon: Icons.lock_outline,
                  isWarning: true,
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '1. Widevine Token License (Android / Web)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_supportsWidevine && _tokenController != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _tokenController!),
                  )
                else
                  const PlatformNoteCard(
                    title: 'Widevine Unsupported on Apple Devices',
                    message:
                        'Apple platforms use FairPlay Streaming DRM instead of Widevine.',
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '2. Widevine License URL (Android / Web)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_supportsWidevine && _widevineController != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _widevineController!),
                  )
                else
                  const PlatformNoteCard(
                    title: 'Widevine Unsupported on Apple Devices',
                    message:
                        'Apple platforms use FairPlay Streaming DRM instead of Widevine.',
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '3. Apple FairPlay (iOS / macOS)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_supportsFairplay && _fairplayController != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _fairplayController!),
                  )
                else
                  const PlatformNoteCard(
                    title: 'FairPlay Unsupported on This Platform',
                    message:
                        'FairPlay Streaming DRM requires Apple hardware and AVPlayer.',
                  ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
