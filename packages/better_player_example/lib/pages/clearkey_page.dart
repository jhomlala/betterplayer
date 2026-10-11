import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:better_player_example/widgets/platform_note_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class ClearKeyPage extends StatefulWidget {
  const ClearKeyPage({super.key});

  @override
  State<StatefulWidget> createState() => _ClearKeyState();
}

class _ClearKeyState extends State<ClearKeyPage> {
  BetterPlayerController? _clearKeyControllerFile;
  BetterPlayerController? _clearKeyControllerBroken;
  BetterPlayerController? _clearKeyControllerNetwork;
  BetterPlayerController? _clearKeyControllerMemory;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      const configuration = PlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
      );
      _clearKeyControllerFile = BetterPlayerController(configuration);
      _clearKeyControllerBroken = BetterPlayerController(configuration);
      _clearKeyControllerNetwork = BetterPlayerController(configuration);
      _clearKeyControllerMemory = BetterPlayerController(configuration);

      _setupDataSources();
    }
  }

  Future<void> _setupDataSources() async {
    final clearKeyDataSourceFile = PlayerDataSource(
      DataSourceType.file,
      await Utils.getFileUrl(Constants.fileTestVideoEncryptUrl),
      drmConfiguration: DrmConfiguration(
        drmType: DrmType.clearKey,
        clearKey: BetterPlayerClearKeyUtils.generateKey({
          'f3c5e0361e6654b28f8049c778b23946':
              'a4631a153a443df9eed0593043db7519',
          'abba271e8bcf552bbd2e86a434a9a5d9':
              '69eaa802a6763af979e8d1940fb88392',
        }),
      ),
    );

    _clearKeyControllerFile?.setupDataSource(clearKeyDataSourceFile);

    final clearKeyDataSourceBroken = PlayerDataSource(
      DataSourceType.file,
      await Utils.getFileUrl(Constants.fileTestVideoEncryptUrl),
      drmConfiguration: DrmConfiguration(
        drmType: DrmType.clearKey,
        clearKey: BetterPlayerClearKeyUtils.generateKey({
          'f3c5e0361e6654b28f8049c778b23946':
              'a4631a153a443df9eed0593043d11111',
          'abba271e8bcf552bbd2e86a434a9a5d9':
              '69eaa802a6763af979e8d1940fb11111',
        }),
      ),
    );

    _clearKeyControllerBroken?.setupDataSource(clearKeyDataSourceBroken);

    final clearKeyDataSourceNetwork = PlayerDataSource(
      DataSourceType.network,
      Constants.networkTestVideoEncryptUrl,
      drmConfiguration: DrmConfiguration(
        drmType: DrmType.clearKey,
        clearKey: BetterPlayerClearKeyUtils.generateKey({
          'f3c5e0361e6654b28f8049c778b23946':
              'a4631a153a443df9eed0593043db7519',
          'abba271e8bcf552bbd2e86a434a9a5d9':
              '69eaa802a6763af979e8d1940fb88392',
        }),
      ),
    );

    _clearKeyControllerNetwork?.setupDataSource(clearKeyDataSourceNetwork);

    final byteData = await rootBundle.load('assets/testvideo_encrypt.mp4');
    final bytes = byteData.buffer.asUint8List();

    final clearKeyDataSourceMemory = PlayerDataSource(
      DataSourceType.memory,
      '',
      bytes: bytes,
      drmConfiguration: DrmConfiguration(
        drmType: DrmType.clearKey,
        clearKey: BetterPlayerClearKeyUtils.generateKey({
          'f3c5e0361e6654b28f8049c778b23946':
              'a4631a153a443df9eed0593043db7519',
          'abba271e8bcf552bbd2e86a434a9a5d9':
              '69eaa802a6763af979e8d1940fb88392',
        }),
      ),
    );

    _clearKeyControllerMemory?.setupDataSource(clearKeyDataSourceMemory);
  }

  @override
  void dispose() {
    _clearKeyControllerFile?.dispose();
    _clearKeyControllerBroken?.dispose();
    _clearKeyControllerNetwork?.dispose();
    _clearKeyControllerMemory?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ClearKey DRM')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'ClearKey Standard Decryption',
                description:
                    'Demonstrates W3C ClearKey encryption using raw key/key ID '
                    'pairs for local files, memory bytes, and network streams.',
                instructions:
                    'Compare valid key streams with the broken key sample (fails decryption).',
                icon: Icons.key_outlined,
              ),
              if (!_isAndroid) ...[
                const PlatformNoteCard(
                  title: 'ClearKey Supported on Android Only',
                  message:
                      'ClearKey DRM is implemented through Android ExoPlayer MediaDrm. '
                      'It is not supported on Web, iOS, macOS, or Windows.',
                  icon: Icons.warning_amber_rounded,
                  isWarning: true,
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '1. Valid File ClearKey',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_clearKeyControllerFile != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _clearKeyControllerFile!),
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '2. Broken Key (Expected Failure)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_clearKeyControllerBroken != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _clearKeyControllerBroken!),
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '3. Network Stream ClearKey',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_clearKeyControllerNetwork != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(
                      controller: _clearKeyControllerNetwork!,
                    ),
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '4. In-Memory Bytes ClearKey',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_clearKeyControllerMemory != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: BetterPlayer(controller: _clearKeyControllerMemory!),
                  ),
                const SizedBox(height: 48),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
