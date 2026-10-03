import 'dart:typed_data';

/// Stub implementation of IO utils.
class ExampleIoUtils {
  static Future<void> writeStringToFile({
    required String path,
    required String content,
  }) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  static Future<void> writeBytesToFile({
    required String path,
    required List<int> bytes,
  }) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  static Future<Uint8List> readBytesFromFile(String path) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }

  static Future<String> writeTempFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    throw UnimplementedError(
      'IO operations are not supported on this platform',
    );
  }
}
