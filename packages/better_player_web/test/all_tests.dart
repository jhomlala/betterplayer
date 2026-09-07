import 'package:flutter/material.dart';
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
      // Note: better_player_web_test.main() uses flutter_test functions 
      // which might throw if not run by 'flutter test'.
      // If they are purely unit tests, they might work or we might need 
      // to adapt them.
      better_player_web_test.main();
      
      print('>>> Running web_video_player_test.main()');
      web_video_player_test.main();
      
      print('--- All Web Tests Finished ---');
    } catch (e, stack) {
      print('Error during test execution: $e');
      print(stack);
    }
  });
}
