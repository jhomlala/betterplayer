import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:flutter/material.dart';

class CachePage extends StatefulWidget {
  @override
  _CachePageState createState() => _CachePageState();
}

class _CachePageState extends State<CachePage> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerDataSource _betterPlayerDataSource;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.phantomVideoUrl,
      cacheConfiguration: BetterPlayerCacheConfiguration(
        useCache: true,
        preCacheSize: 10 * 1024 * 1024,
        maxCacheSize: 10 * 1024 * 1024,
        maxCacheFileSize: 10 * 1024 * 1024,

        ///Android only option to use cached video between app sessions
        key: "testCacheKey",
      ),
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cache"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Player with cache enabled. To test this feature, first plays "
              "video, then leave this page, turn internet off and enter "
              "page again. You should be able to play video without "
              "internet connection.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
          TextButton(
            child: Text("Start pre cache"),
            onPressed: () {
              _betterPlayerController.preCache(_betterPlayerDataSource);
            },
          ),
          TextButton(
            child: Text("Stop pre cache"),
            onPressed: () {
              _betterPlayerController.stopPreCache(_betterPlayerDataSource);
            },
          ),
          TextButton(
            child: Text("Play video"),
            onPressed: () {
              _betterPlayerController.setupDataSource(_betterPlayerDataSource);
            },
          ),
          TextButton(
            child: Text("Clear cache"),
            onPressed: () {
              _betterPlayerController.clearCache();
            },
          ),
        ],
      ),
    );
  }
}
