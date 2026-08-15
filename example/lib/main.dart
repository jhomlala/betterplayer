import 'package:better_player/better_player.dart';
import 'package:example/constants.dart';
import 'package:example/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as m3;

void main() => runApp(const BetterPlayerExample());

class BetterPlayerExample extends StatelessWidget {
  const BetterPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        m3.GlobalMaterialLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(title: const Text('Better Player Example')),
        body: Column(
          children: [
            const SizedBox(height: 8),
            BetterPlayer.network(
              Constants.bugBuckBunnyVideoUrl,
              betterPlayerConfiguration: const BetterPlayerConfiguration(
                aspectRatio: 16 / 9,
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) => ElevatedButton(
                child: const Text('Open Full Showcase'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const WelcomePage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
