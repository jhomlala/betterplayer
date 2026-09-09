import 'dart:io';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile/Desktop implementation of IO utils using dart:io.
@internal
class BetterPlayerIoUtils {
  /// Deletes a file at the given [path].
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Checks if a file exists at the given [path].
  static bool fileExists(String path) {
    return File(path).existsSync();
  }

  /// Reads the content of a file at the given [path] as a string.
  static Future<String> readFileAsString(String path) async {
    return File(path).readAsString();
  }

  /// Writes the given [bytes] to a file at the given [path].
  static Future<void> writeBytes(String path, List<int> bytes) async {
    await File(path).writeAsBytes(bytes);
  }

  /// Returns a temporary file path with the given [fileName].
  static Future<String> getTempPath(String fileName) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$fileName';
  }
}
