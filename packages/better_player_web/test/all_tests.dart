import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'better_player_web_test.dart' as better_player_web_test;
import 'web_video_player_test.dart' as web_video_player_test;

void main() {
  // Simple app to trigger test execution
  runApp(
    MaterialApp(
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
  Future.delayed(Duration(seconds: 3), () async {
    print('--- Starting All Web Tests ---');
    
    try {
      print('>>> Running better_player_web_test.main()');
      better_player_web_test.main();
      
      print('>>> Running web_video_player_test.main()');
      web_video_player_test.main();
      
      tearDownAll(() {
        print('=== ALL WEB TESTS FINISHED ===');
        // Attempt to close the browser window/tab to stop the runner
        try {
          web.window.close();
        } catch (e) {
          print('Could not close window: $e');
        }
      });
    } catch (e, stack) {
      print('Error during test registration: $e');
      print(stack);
    }
  });
}
