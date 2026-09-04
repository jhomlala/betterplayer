import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:material_ui/material_ui.dart';

class FadePlaceholderPage extends StatefulWidget {
  const FadePlaceholderPage({super.key});

  @override
  _FadePlaceholderPageState createState() => _FadePlaceholderPageState();
}

class _FadePlaceholderPageState extends State<FadePlaceholderPage> {
  late BetterPlayerController _betterPlayerController;
  final StreamController<bool> _playController = StreamController.broadcast();

  @override
  void initState() {
    final betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      placeholder: _FadePlaceholder(playStream: _playController.stream),
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
        _playController.add(false);
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
  const _FadePlaceholder({required this.playStream});

  final Stream<bool> playStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: playStream,
      builder: (context, snapshot) {
        final showPlaceholder = snapshot.data ?? true;
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
