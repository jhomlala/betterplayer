import 'dart:io';
import 'package:better_player/src/utils/player_io_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerIoUtils tests', () {
    test('fileExists returns true for existing file', () async {
      final file = File('${Directory.systemTemp.path}/test_file.txt');
      await file.writeAsString('test');
      expect(PlayerIoUtils.fileExists(file.path), true);
      await file.delete();
    });

    test('fileExists returns false for non-existing file', () {
      expect(PlayerIoUtils.fileExists('non_existing_file.txt'), false);
    });

    test('readFileAsString reads content', () async {
      final file = File('${Directory.systemTemp.path}/test_file_read.txt');
      await file.writeAsString('hello world');
      final content = await PlayerIoUtils.readFileAsString(file.path);
      expect(content, 'hello world');
      await file.delete();
    });

    test('writeBytes writes data', () async {
      final path = '${Directory.systemTemp.path}/test_file_bytes.bin';
      final bytes = [1, 2, 3, 4];
      await PlayerIoUtils.writeBytes(path, bytes);
      final file = File(path);
      expect(await file.readAsBytes(), bytes);
      await file.delete();
    });

    test('deleteFile deletes file', () async {
      final file = File('${Directory.systemTemp.path}/test_file_delete.txt');
      await file.writeAsString('test');
      expect(file.existsSync(), true);
      await PlayerIoUtils.deleteFile(file.path);
      expect(file.existsSync(), false);
    });
  });
}
