import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/material.dart';

class FadePlaceholderPage extends StatefulWidget {
  @override
  _FadePlaceholderPageState createState() => _FadePlaceholderPageState();
}

class _FadePlaceholderPageState extends State<FadePlaceholderPage> {
  BetterPlayerController _betterPlayerController;
  StreamController<bool> _playController = StreamController.broadcast();

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      placeholder: _buildPlaceholder(),
      showPlaceholderUntilPlay: true,
      placeholderOnTop: false,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      Constants.forBiggerBlazesUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        _playController.add(false);
      }
    });
    super.initState();
  }

  Widget _buildPlaceholder() {
    return StreamBuilder<bool>(
      stream: _playController.stream,
      builder: (context, snapshot) {
        bool showPlaceholder = snapshot.data ?? true;
        return AnimatedOpacity(
          duration: Duration(milliseconds: 500),
          opacity: showPlaceholder ? 1.0 : 0.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              "https://img.webmd.com/dtmcms/live/webmd/consumer_assets/site_images/article_thumbnails/other/cat_relaxing_on_patio_other/1800x1200_cat_relaxing_on_patio_other.jpg",
              fit: BoxFit.fill,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fade placeholder player"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Normal player with configuration managed by developer.",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }
}
