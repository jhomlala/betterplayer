import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
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
      appBar: AppBar(title: const Text('Placeholder Until Play')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Cover Poster Layer',
                description:
                    'Displays placeholder graphic until playback starts for the '
                    'first time, preventing black frames while buffering.',
                instructions:
                    'Tap play to hide poster and begin video rendering.',
                icon: Icons.image_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
