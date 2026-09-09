import 'dart:typed_data';

/// Stub implementation of IO utils.
class ExampleIoUtils {
  static Future<void> writeStringToFile(String path, String content) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  static Future<void> writeBytesToFile(String path, List<int> bytes) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  static Future<Uint8List> readBytesFromFile(String path) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }
}
