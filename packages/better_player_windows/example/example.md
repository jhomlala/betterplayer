# Better Player Windows Example

Below is an example showing how to initialize and use `BetterPlayer` on Windows. For more extensive examples, see the [better_player_example](https://pub.dev/packages/better_player_example) package.

```dart
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

void main() => runApp(const BetterPlayerExample());

class BetterPlayerExample extends StatelessWidget {
  const BetterPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Better Player Windows Example')),
        body: Column(
          children: [
            const SizedBox(height: 8),
            BetterPlayer.network(
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              betterPlayerConfiguration: const PlayerConfiguration(
                aspectRatio: 16 / 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
