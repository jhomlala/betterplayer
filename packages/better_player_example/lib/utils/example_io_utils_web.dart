import 'dart:typed_data';

/// Web implementation of IO utils.
class ExampleIoUtils {
  static Future<void> writeStringToFile(String path, String content) async {
    // No-op on web
  }

  static Future<void> writeBytesToFile(String path, List<int> bytes) async {
    // No-op on web
  }

  static Future<Uint8List> readBytesFromFile(String path) async {
    throw UnsupportedError('Reading local files is not supported on web');
  }
}
