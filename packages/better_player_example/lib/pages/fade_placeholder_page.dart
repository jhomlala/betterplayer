import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class FadePlaceholderPage extends StatefulWidget {
  const FadePlaceholderPage({super.key});

  @override
  _FadePlaceholderPageState createState() => _FadePlaceholderPageState();
}

class _FadePlaceholderPageState extends State<FadePlaceholderPage> {
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
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      placeholder: _FadePlaceholder(
        showPlaceholderListenable: _showPlaceholderNotifier,
      ),
      showPlaceholderUntilPlay: true,
      placeholderOnTop: false,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.forBiggerBlazesUrl,
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
      appBar: AppBar(title: const Text('Fade placeholder player')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Normal player with placeholder which fade.',
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

class _FadePlaceholder extends StatelessWidget {
  const _FadePlaceholder({required this.showPlaceholderListenable});

  final ValueListenable<bool> showPlaceholderListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showPlaceholderListenable,
      builder: (context, showPlaceholder, _) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: showPlaceholder ? 1.0 : 0.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(Constants.catImageUrl, fit: BoxFit.fill),
          ),
        );
      },
    );
  }
}
