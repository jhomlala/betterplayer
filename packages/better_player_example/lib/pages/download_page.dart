import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_downloader/better_player_downloader.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _request = DownloadRequest(url: Constants.dashBigBuckBunnyUrl);
  static const _pollInterval = Duration(milliseconds: 500);

  late final BetterPlayerController _controller;
  Timer? _poll;
  DownloadProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      const PlayerConfiguration(aspectRatio: 16 / 9, fit: BoxFit.contain),
    );
    _watchProgress();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() => _error = null);
    final result = await BetterPlayerDownloader.startDownload(_request);
    if (!mounted) {
      return;
    }
    switch (result) {
      case DownloadErr(:final message):
        setState(() => _error = message);
      case DownloadRequiresNativeService():
        setState(() => _error = 'Native download service is not available.');
      case DownloadOk():
        _watchProgress();
    }
  }

  Future<void> _deleteDownload() async {
    final deleted = await BetterPlayerDownloader.deleteDownload(_request);
    if (!mounted) {
      return;
    }
    setState(() {
      _progress = null;
      _error = deleted ? null : 'No download to delete.';
    });
  }

  void _watchProgress() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (timer) async {
      final progress = await BetterPlayerDownloader.downloadProgress(_request);
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _progress = progress);
      if (progress != null &&
          (progress.state == DownloadState.completed ||
              progress.state == DownloadState.failed)) {
        timer.cancel();
      }
    });
  }

  void _play() {
    _controller.setupDataSource(
      PlayerDataSource(
        DataSourceType.network,
        Constants.dashBigBuckBunnyUrl,
        cacheConfiguration: const CacheConfiguration(
          useCache: true,
          preCacheSize: 3 * 1024 * 1024 * 1024,
        ),
      ),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) {
      return '0 MB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _statusLabel() {
    final progress = _progress;
    if (progress == null) {
      return 'Not started';
    }
    switch (progress.state) {
      case DownloadState.notStarted:
        return 'Not started';
      case DownloadState.inProgress:
        return 'Downloading';
      case DownloadState.completed:
        return 'Completed';
      case DownloadState.failed:
        return 'Failed';
    }
  }

  Widget _sizeText() {
    final progress = _progress;
    if (progress == null) {
      return const Text('No download record.');
    }
    return Text(
      '${_sizeLabel(progress.bytesDownloaded)} / '
      '${_sizeLabel(progress.totalBytes)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
      appBar: AppBar(title: const Text('Stream Downloads')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'DASH & HLS Downloads',
                description:
                    'Downloads every segment of a DASH or HLS stream into the '
                    'player cache, so the same URL plays without a network.',
                instructions:
                    'Start the download, wait for completion, then enable '
                    'airplane mode and press Play.',
                icon: Icons.download_for_offline_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _controller),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _play,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                    if (!kIsWeb) ...[
                      FilledButton.tonalIcon(
                        onPressed: _startDownload,
                        icon: const Icon(Icons.download),
                        label: const Text('Start Download'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _deleteDownload,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Download'),
                      ),
                    ],
                  ],
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _statusLabel(),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${progress?.percent ?? 0}%',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (progress?.percent ?? 0) / 100,
                          ),
                          const SizedBox(height: 8),
                          _sizeText(),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
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
