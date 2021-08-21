import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class DownloadSource extends StatefulWidget {
  const DownloadSource({
    Key? key,
    required this.dataSource,
  }) : super(key: key);

  final BetterPlayerDataSource dataSource;

  @override
  _DownloadSourceState createState() => _DownloadSourceState();
}

class _DownloadSourceState extends State<DownloadSource> {
  double? downloadProgress;
  bool isDownloaded = false;
  bool initialized = false;

  @override
  void initState() {
    BetterPlayerDownloader.downloadedAssets().then((downloads) {
      setState(() {
        isDownloaded = downloads.containsKey(widget.dataSource.url);
        initialized = true;
      });
    });

    super.initState();
  }

  Future<void> download() async {
    final progressStream = BetterPlayerDownloader.download(
      url: widget.dataSource.url,
      drmConfiguration: widget.dataSource.drmConfiguration,
      videoFormat: widget.dataSource.videoFormat,
    );

    setState(() {
      downloadProgress = 0;
    });

    await for (final progress in progressStream) {
      setState(() {
        downloadProgress = progress;
      });
    }

    setState(() {
      downloadProgress = null;
      isDownloaded = true;
    });
  }

  Future<void> removeDownload() async {
    await BetterPlayerDownloader.remove(widget.dataSource.url);

    setState(() {
      isDownloaded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (initialized && downloadProgress != null)
            Text('${downloadProgress!.toStringAsFixed(2)}%')
          else if (initialized && isDownloaded)
            Text('The video is downloaded! You can go offline.'),
          const Spacer(),
          if (!initialized || downloadProgress != null)
            const CircularProgressIndicator()
          else if (isDownloaded)
            IconButton(
              onPressed: removeDownload,
              icon: Icon(Icons.download_done),
            )
          else
            IconButton(
              onPressed: download,
              icon: Icon(Icons.download),
            ),
        ],
      ),
    );
  }
}
