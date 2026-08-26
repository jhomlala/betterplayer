# Better Player Example

Below is a simple example showing how to initialize and use `BetterPlayer`. For more extensive examples, please see the [better_player_example](https://pub.dev/packages/better_player_example) package.

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
        appBar: AppBar(title: const Text('Better Player Simple Example')),
        body: Column(
          children: [
            const SizedBox(height: 8),
            BetterPlayer.network(
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              betterPlayerConfiguration: const BetterPlayerConfiguration(
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
