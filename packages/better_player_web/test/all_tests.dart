import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'better_player_web_player_test.dart' as better_player_web_player_test;
import 'better_player_web_test.dart' as better_player_web_test;

void main() {
  // Simple app to trigger test execution
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Running Web Tests...'),
            SizedBox(height: 20),
            Text('Check console for results.'),
          ],
        ),
      ),
    ),
  );

  // We use a small delay to let the app settle
  Future<void>.delayed(const Duration(seconds: 3), () async {
    try {
      better_player_web_test.main();
      better_player_web_player_test.main();
    } on Object {
      // Ignored.
    }
  });
}
