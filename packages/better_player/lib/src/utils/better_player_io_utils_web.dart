import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Web implementation of IO utils.
/// Most operations are no-ops or throw as they are not supported on web.
@internal
class BetterPlayerIoUtils {
  /// Deletes a file at the given [path]. No-op on web.
  static Future<void> deleteFile(String path) async {
    // No-op on web
  }

  /// Checks if a file exists at the given [path]. Always false on web.
  static bool fileExists(String path) {
    return false;
  }

  /// Reads the content of a file at the given [path] as a string. Throws on web.
  static Future<String> readFileAsString(String path) async {
    throw UnimplementedError('Reading local files is not supported on web');
  }

  /// Writes the given [bytes] to a file at the given [path]. No-op on web.
  static Future<void> writeBytes(String path, List<int> bytes) async {
    // No-op on web
  }

  /// Returns a temporary file path with the given [fileName]. Returns filename on web.
  static Future<String> getTempPath(String fileName) async {
    return fileName;
  }
}
