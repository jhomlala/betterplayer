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
  PreCacheProgress? _preCacheProgress;
  bool _isPreCaching = false;

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
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    final mb = bytes / (1024 * 1024);
    if (mb >= 0.1) {
      return '${mb.toStringAsFixed(2)} MB';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }

  String _formatBytesProgress(PreCacheProgress? progress) {
    if (progress == null) {
      return 'Connecting...';
    }
    final downloaded = _formatBytes(progress.bytesDownloaded);
    final total = progress.totalBytes > 0
        ? _formatBytes(progress.totalBytes)
        : 'Unknown size';
    return '$downloaded / $total';
  }

  void _startPreCache() {
    setState(() {
      _isPreCaching = true;
      _preCacheProgress = null;
    });
    _betterPlayerController
        .preCache(
          _betterPlayerDataSource,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _preCacheProgress = progress;
              });
            }
          },
        )
        .catchError((Object error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pre-cache error: $error')),
            );
          }
        })
        .whenComplete(() {
          if (mounted) {
            setState(() {
              _isPreCaching = false;
            });
          }
        });
  }

  void _stopPreCache() {
    _betterPlayerController.stopPreCache(_betterPlayerDataSource);
    setState(() {
      _isPreCaching = false;
    });
  }

  void _clearCache() {
    _betterPlayerController.clearCache();
    setState(() {
      _preCacheProgress = null;
      _isPreCaching = false;
    });
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
                        onPressed: _isPreCaching ? null : _startPreCache,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Pre-cache'),
                        onPressed: _stopPreCache,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Cache'),
                        onPressed: _clearCache,
                      ),
                    ],
                  ],
                ),
              ),
              if (!kIsWeb && (_isPreCaching || _preCacheProgress != null)) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isPreCaching
                                    ? 'Pre-caching in progress...'
                                    : 'Pre-cache completed',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${(_preCacheProgress?.percent ?? (_isPreCaching ? 0.0 : 100.0)).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _preCacheProgress != null
                                ? _preCacheProgress!.progress.clamp(0.0, 1.0)
                                : (_isPreCaching ? null : 1.0),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatBytesProgress(_preCacheProgress),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
