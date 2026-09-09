import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Stub implementation of IO utils for unsupported platforms.
@internal
class BetterPlayerIoUtils {
  /// Deletes a file at the given [path].
  static Future<void> deleteFile(String path) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  /// Checks if a file exists at the given [path].
  static bool fileExists(String path) {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  /// Reads the content of a file at the given [path] as a string.
  static Future<String> readFileAsString(String path) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  /// Writes the given [bytes] to a file at the given [path].
  static Future<void> writeBytes(String path, List<int> bytes) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  /// Returns a temporary file path with the given [fileName].
  static Future<String> getTempPath(String fileName) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }
}
