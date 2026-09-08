import 'dart:convert';
import 'dart:io';

void main() async {
  print('🚀 Starting web tests via flutter run...');

  // Start the flutter run process
  final process = await Process.start(
    'flutter',
    ['run', '-d', 'chrome', 'test/all_tests.dart'],
    workingDirectory: 'packages/better_player_web',
    runInShell: true,
  );

  int finalExitCode = 1; // Default to failure if it exits unexpectedly
  bool finished = false;

  void terminateProcess() {
    if (finished) return;
    finished = true;

    // On Windows, process.kill() only kills the parent flutter.bat, leaving Chrome open.
    // We use taskkill to kill the whole process tree.
    if (Platform.isWindows) {
      Process.runSync('taskkill', ['/F', '/T', '/PID', process.pid.toString()]);
    } else {
      process.kill();
    }
  }

  // Listen to standard output line by line
  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      print(line); // Forward the output to your terminal

      // DETECT SUCCESS
      if (line.contains('All tests passed!')) {
        print('\n✅ Success detected! Closing browser...');
        finalExitCode = 0;
        terminateProcess();
      }
      // DETECT FAILURE
      else if (line.contains('Some tests failed.')) {
        print('\n❌ Failure detected! Closing browser...');
        finalExitCode = 1;
        terminateProcess();
      }
    },
  );

  // Forward standard error just in case
  process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      print('[STDERR] $line');
    },
  );

  // Wait for the process to fully close, then exit with the correct code
  await process.exitCode;
  exit(finalExitCode);
}
