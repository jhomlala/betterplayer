import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class CachePage extends StatefulWidget {
  const CachePage({super.key});

  @override
  _CachePageState createState() => _CachePageState();
}

class _CachePageState extends State<CachePage> {
  late BetterPlayerController _betterPlayerController;
  late PlayerDataSource _betterPlayerDataSource;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _betterPlayerDataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.phantomVideoUrl,
      cacheConfiguration: const CacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024,

        ///Option to use cached video between app sessions
        key: 'testCacheKey',
      ),
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Caching')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Native Cache & Pre-caching',
                description: kIsWeb
                    ? 'Caching is not supported on Flutter Web because browsers handle media caching.'
                    : 'Caches downloaded segments locally. Play once, disconnect network, '
                          'and verify seamless offline playback.',
                instructions: kIsWeb
                    ? null
                    : 'Use pre-cache actions below to buffer 10 MB ahead of playback.',
                icon: Icons.cached_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Video'),
                      onPressed: () {
                        _betterPlayerController.setupDataSource(
                          _betterPlayerDataSource,
                        );
                      },
                    ),
                    if (!kIsWeb) ...[
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.download),
                        label: const Text('Start Pre-cache'),
                        onPressed: () {
                          _betterPlayerController.preCache(
                            _betterPlayerDataSource,
                          );
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Pre-cache'),
                        onPressed: () {
                          _betterPlayerController.stopPreCache(
                            _betterPlayerDataSource,
                          );
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Cache'),
                        onPressed: () {
                          _betterPlayerController.clearCache();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
