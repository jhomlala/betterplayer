import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Utils {
  static Future<String> getFileUrl(String fileName) async {
    if (kIsWeb) {
      return '';
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
