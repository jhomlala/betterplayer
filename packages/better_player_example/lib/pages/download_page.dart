import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String _url = Constants.dashBigBuckBunnyUrl;

  late final BetterPlayerController _controller;
  late final StreamSubscription<DownloadProgress> _subscription;
  DownloadProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      const PlayerConfiguration(aspectRatio: 16 / 9, fit: BoxFit.contain),
    );
    _subscription = _controller.downloadProgressStream.listen((progress) {
      if (progress.url == _url) {
        setState(() => _progress = progress);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() => _error = null);
    try {
      await _controller.startDownload(
        PlayerDataSource(DataSourceType.network, _url),
      );
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    }
  }

  void _selectUrl(String url) {
    if (url == _url) {
      return;
    }
    setState(() {
      _url = url;
      _progress = null;
      _error = null;
    });
  }

  Future<void> _stopDownload() async {
    await _controller.stopDownload(_url);
  }

  Future<void> _deleteDownload() async {
    await _controller.deleteDownload(_url);
    if (!mounted) {
      return;
    }
    setState(() => _progress = null);
  }

  void _play() {
    _controller.setupDataSource(
      PlayerDataSource(DataSourceType.network, _url),
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
      case DownloadState.queued:
        return 'Queued';
      case DownloadState.downloading:
        return 'Downloading';
      case DownloadState.paused:
        return 'Paused';
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
    if (!progress.hasTotalBytes) {
      return Text('${_sizeLabel(progress.bytesDownloaded)} stored');
    }
    return Text(
      '${_sizeLabel(progress.bytesDownloaded)} / '
      '${_sizeLabel(progress.totalBytes)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final error = _error ?? progress?.error;
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
                    'Downloads one video track of a DASH or HLS stream, so the '
                    'same URL plays without a network.',
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
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: Constants.dashBigBuckBunnyUrl,
                      label: const Text('DASH'),
                    ),
                    const ButtonSegment(
                      value: Constants.hlsTestStreamUrl,
                      label: Text('HLS'),
                    ),
                  ],
                  selected: {_url},
                  onSelectionChanged: (selection) =>
                      _selectUrl(selection.first),
                ),
              ),
              const SizedBox(height: 8),
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
                        onPressed: _stopDownload,
                        icon: const Icon(Icons.pause),
                        label: const Text('Stop Download'),
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
                          Text(
                            _statusLabel(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value:
                                progress != null &&
                                    progress.isActive &&
                                    !progress.hasTotalBytes
                                ? null
                                : progress?.fraction,
                          ),
                          const SizedBox(height: 8),
                          _sizeText(),
                          if (error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              error,
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
