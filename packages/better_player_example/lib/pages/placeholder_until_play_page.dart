import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class PlaceholderUntilPlayPage extends StatefulWidget {
  const PlaceholderUntilPlayPage({super.key});

  @override
  _PlaceholderUntilPlayPageState createState() =>
      _PlaceholderUntilPlayPageState();
}

class _PlaceholderUntilPlayPageState extends State<PlaceholderUntilPlayPage> {
  late BetterPlayerController _betterPlayerController;
  final ValueNotifier<bool> _showPlaceholderNotifier = ValueNotifier<bool>(
    true,
  );

  @override
  void dispose() {
    _showPlaceholderNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    final betterPlayerConfiguration = PlayerConfiguration(
      fit: BoxFit.contain,
      placeholder: _VideoPlaceholder(
        showPlaceholderListenable: _showPlaceholderNotifier,
      ),
      showPlaceholderUntilPlay: true,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.addEventsListener((event) {
      if (event.betterPlayerEventType == PlayerEventType.play) {
        _showPlaceholderNotifier.value = false;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Placeholder until play')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Normal player with placeholder shown until video is started.',
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

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({
    required this.showPlaceholderListenable,
  });

  final ValueListenable<bool> showPlaceholderListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showPlaceholderListenable,
      builder: (context, showPlaceholder, _) {
        return showPlaceholder
            ? Image.network(Constants.placeholderUrl)
            : const SizedBox();
      },
    );
  }
}
