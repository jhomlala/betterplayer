import 'dart:typed_data';

/// Web implementation of IO utils.
class ExampleIoUtils {
  static Future<void> writeStringToFile({
    required String path,
    required String content,
  }) async {
    // No-op on web
  }

  static Future<void> writeBytesToFile({
    required String path,
    required List<int> bytes,
  }) async {
    // No-op on web
  }

  static Future<Uint8List> readBytesFromFile(String path) async {
    throw UnsupportedError('Reading local files is not supported on web');
  }

  static Future<String> writeTempFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    throw UnsupportedError('Writing temp files is not supported on web');
  }
}
