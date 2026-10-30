import 'dart:io';
import 'dart:typed_data';

/// Fails if a screenshot shows (almost) no video pixels.
///
/// Regression check for #1632: on the iOS Simulator audio played while the
/// video stayed black. The e2e page uses a solid black placeholder, so a black
/// center region means the platform view rendered nothing.
///
/// Usage: dart scripts/check_video_frame.dart <screenshot.png> [...]
const double _minBrightRatio = 0.05;
const double _lumaMin = 24;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart scripts/check_video_frame.dart <png> [...]');
    exit(2);
  }
  var failed = false;
  for (final path in args) {
    final file = _resolveFile(path);
    if (file == null) {
      stderr.writeln('$path: file does not exist');
      failed = true;
      continue;
    }
    final ratio = brightRatio(file.readAsBytesSync());
    final ok = ratio >= _minBrightRatio;
    stdout.writeln(
      '${file.path}: bright pixel ratio ${ratio.toStringAsFixed(3)} '
      '(${ok ? 'ok' : 'BLACK'})',
    );
    failed = failed || !ok;
  }
  exit(failed ? 1 : 0);
}

File? _resolveFile(String path) {
  final direct = File(path);
  if (direct.existsSync()) {
    return direct;
  }
  final filename = path.contains('/') || path.contains(r'\')
      ? path.split(RegExp(r'[/\\]')).last
      : path;

  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  if (home.isNotEmpty) {
    final maestroDir = Directory('$home/.maestro/tests');
    if (maestroDir.existsSync()) {
      try {
        for (final entity in maestroDir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith(filename)) {
            return entity;
          }
        }
      } catch (_) {}
    }
  }

  try {
    for (final entity in Directory.current.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith(filename)) {
        return entity;
      }
    }
  } catch (_) {}

  return null;
}

/// Share of sampled center pixels brighter than [_lumaMin].
double brightRatio(Uint8List png) {
  final image = _decodePng(png);
  // Center 60% of the screen: skips status bar and the status label.
  final x0 = (image.width * 0.2).toInt();
  final x1 = (image.width * 0.8).toInt();
  final y0 = (image.height * 0.3).toInt();
  final y1 = (image.height * 0.7).toInt();
  var total = 0;
  var bright = 0;
  for (var y = y0; y < y1; y += 4) {
    final row = image.rows[y];
    for (var x = x0; x < x1; x += 4) {
      final i = x * image.channels;
      final luma = 0.299 * row[i] + 0.587 * row[i + 1] + 0.114 * row[i + 2];
      total++;
      if (luma > _lumaMin) {
        bright++;
      }
    }
  }
  return total == 0 ? 0 : bright / total;
}

class _Image {
  _Image(this.width, this.height, this.channels, this.rows);
  final int width;
  final int height;
  final int channels;
  final List<Uint8List> rows;
}

_Image _decodePng(Uint8List data) {
  const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < 8; i++) {
    if (data[i] != signature[i]) {
      throw const FormatException('Not a PNG file.');
    }
  }
  final view = ByteData.sublistView(data);
  var pos = 8;
  var width = 0;
  var height = 0;
  var channels = 0;
  final idat = BytesBuilder();
  while (pos < data.length) {
    final length = view.getUint32(pos);
    final type = String.fromCharCodes(data.sublist(pos + 4, pos + 8));
    final start = pos + 8;
    if (type == 'IHDR') {
      width = view.getUint32(start);
      height = view.getUint32(start + 4);
      final depth = data[start + 8];
      final color = data[start + 9];
      final interlace = data[start + 12];
      if (depth != 8 || (color != 2 && color != 6) || interlace != 0) {
        throw const FormatException('Unsupported PNG format.');
      }
      channels = color == 6 ? 4 : 3;
    } else if (type == 'IDAT') {
      idat.add(data.sublist(start, start + length));
    } else if (type == 'IEND') {
      break;
    }
    pos = start + length + 4;
  }
  final raw = Uint8List.fromList(zlib.decode(idat.toBytes()));
  final stride = width * channels;
  final rows = <Uint8List>[];
  var prev = Uint8List(stride);
  var offset = 0;
  for (var y = 0; y < height; y++) {
    final filter = raw[offset];
    final line = Uint8List.fromList(
      raw.sublist(offset + 1, offset + 1 + stride),
    );
    offset += 1 + stride;
    for (var i = 0; i < stride; i++) {
      final a = i >= channels ? line[i - channels] : 0;
      final b = prev[i];
      final c = i >= channels ? prev[i - channels] : 0;
      line[i] = (line[i] + _predict(filter, a, b, c)) & 0xFF;
    }
    rows.add(line);
    prev = line;
  }
  return _Image(width, height, channels, rows);
}

int _predict(int filter, int a, int b, int c) {
  switch (filter) {
    case 1:
      return a;
    case 2:
      return b;
    case 3:
      return (a + b) >> 1;
    case 4:
      final p = a + b - c;
      final pa = (p - a).abs();
      final pb = (p - b).abs();
      final pc = (p - c).abs();
      if (pa <= pb && pa <= pc) {
        return a;
      }
      return pb <= pc ? b : c;
    default:
      return 0;
  }
}
