import 'package:better_player_example/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as m3;

void main() => runApp(const BetterPlayerExample());

class BetterPlayerExample extends StatelessWidget {
  const BetterPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        m3.GlobalMaterialLocalizations.delegate,
      ],
      home: WelcomePage(),
    );
  }
}
