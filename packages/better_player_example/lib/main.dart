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
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2563EB),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFDBEAFE),
          onPrimaryContainer: Color(0xFF1E40AF),
          secondary: Color(0xFF475569),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFF1F5F9),
          onSecondaryContainer: Color(0xFF0F172A),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF0F172A),
          surfaceContainerHighest: Color(0xFFF1F5F9),
          onSurfaceVariant: Color(0xFF64748B),
          outline: Color(0xFFCBD5E1),
          outlineVariant: Color(0xFFE2E8F0),
          error: Color(0xFFDC2626),
          onError: Colors.white,
          errorContainer: Color(0xFFFEE2E2),
          onErrorContainer: Color(0xFF991B1B),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        scaffoldBackgroundColor: const Color(0xFF020617),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF3B82F6),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF1E3A8A),
          onPrimaryContainer: Color(0xFFDBEAFE),
          secondary: Color(0xFF94A3B8),
          onSecondary: Color(0xFF0F172A),
          secondaryContainer: Color(0xFF1E293B),
          onSecondaryContainer: Color(0xFFF1F5F9),
          surface: Color(0xFF0F172A),
          onSurface: Color(0xFFF8FAFC),
          surfaceContainerHighest: Color(0xFF1E293B),
          onSurfaceVariant: Color(0xFF94A3B8),
          outline: Color(0xFF475569),
          outlineVariant: Color(0xFF334155),
          error: Color(0xFFEF4444),
          onError: Colors.white,
          errorContainer: Color(0xFF7F1D1D),
          onErrorContainer: Color(0xFFFEE2E2),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF0F172A),
          surfaceTintColor: Colors.transparent,
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
