import 'dart:io';
import 'dart:typed_data';

/// Mobile/Desktop implementation of IO utils using dart:io.
class ExampleIoUtils {
  static Future<void> writeStringToFile({
    required String path,
    required String content,
  }) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  static Future<void> writeBytesToFile({
    required String path,
    required List<int> bytes,
  }) async {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }

  static Future<Uint8List> readBytesFromFile(String path) async {
    final file = File(path);
    return file.readAsBytes();
  }

  static Future<String> writeTempFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }
}
