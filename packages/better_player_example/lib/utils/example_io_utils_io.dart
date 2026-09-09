import 'dart:io';
import 'dart:typed_data';

/// Mobile/Desktop implementation of IO utils using dart:io.
class ExampleIoUtils {
  static Future<void> writeStringToFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  static Future<void> writeBytesToFile(String path, List<int> bytes) async {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }

  static Future<Uint8List> readBytesFromFile(String path) async {
    final file = File(path);
    return file.readAsBytes();
  }
}
