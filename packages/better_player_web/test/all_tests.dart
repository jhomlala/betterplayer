import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'better_player_web_test.dart' as better_player_web_test;
import 'web_video_player_test.dart' as web_video_player_test;

void main() {
  // Simple app to trigger test execution
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Running Web Tests...'),
              Text('Check console for results.'),
            ],
          ),
        ),
      ),
    ),
  );

  // We use a small delay to let the app settle
  Future<void>.delayed(const Duration(seconds: 3), () async {
    debugPrint('--- Starting All Web Tests ---');

    try {
      debugPrint('>>> Running better_player_web_test.main()');
      better_player_web_test.main();

      debugPrint('>>> Running web_video_player_test.main()');
      web_video_player_test.main();

      tearDownAll(() async {
        debugPrint('=== ALL WEB TESTS FINISHED ===');
        // Attempt to close the browser window/tab to stop the runner
      });
    } catch (e, stack) {
      debugPrint('Error during test registration: $e');
      debugPrint(stack.toString());
    }
  });
}
