# Better Player Tizen Example (EXPERIMENTAL)

Below is an example showing how to initialize and use `BetterPlayer` on Tizen OS / Samsung Smart TVs. For more extensive examples, see the main [better_player_example](https://pub.dev/packages/better_player_example) package.

```dart
import 'package:better_player/better_player.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  BetterPlayerTizen.register();
  runApp(const BetterPlayerExample());
}

class BetterPlayerExample extends StatelessWidget {
  const BetterPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Better Player Tizen Example')),
        body: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer.network(
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              betterPlayerConfiguration: const PlayerConfiguration(
                aspectRatio: 16 / 9,
                autoPlay: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```
