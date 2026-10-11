import 'package:better_player_example/pages/welcome_page.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as c1;
import 'package:material_ui/material_ui.dart';

void main() => runApp(const BetterPlayerExample());

/// Root widget for Better Player example application.
class BetterPlayerExample extends StatefulWidget {
  const BetterPlayerExample({super.key});

  /// Inherited helper to update theme mode from nested widgets.
  static void setThemeMode(BuildContext context, ThemeMode mode) {
    final state = context.findAncestorStateOfType<_BetterPlayerExampleState>();
    state?._updateThemeMode(mode);
  }

  /// Inherited helper to access current theme mode.
  static ThemeMode themeModeOf(BuildContext context) {
    final state = context.findAncestorStateOfType<_BetterPlayerExampleState>();
    return state?._themeMode ?? ThemeMode.system;
  }

  @override
  State<BetterPlayerExample> createState() => _BetterPlayerExampleState();
}

class _BetterPlayerExampleState extends State<BetterPlayerExample> {
  ThemeMode _themeMode = ThemeMode.system;

  void _updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Player',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        c1.GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('pl', 'PL'),
        Locale('zh', 'CN'),
        Locale('hi', 'IN'),
        Locale('tr', 'TR'),
        Locale('vi', 'VN'),
        Locale('es', 'ES'),
        Locale('fa', 'IR'),
        Locale('pt', 'BR'),
      ],
      home: const WelcomePage(),
    );
  }
}
