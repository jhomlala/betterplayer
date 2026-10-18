import 'dart:io';
import 'dart:typed_data';

/// Serves a video fixture, including byte ranges requested by native players.
Future<void> serveVideoRequest({
  required HttpRequest request,
  required Uint8List bytes,
}) async {
  final response = request.response;
  response.headers.contentType = ContentType('video', 'mp4');
  response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

  final range = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(
    request.headers.value(HttpHeaders.rangeHeader) ?? '',
  );
  final start = int.parse(range?[1] ?? '0');
  final end =
      int.tryParse(range?[2] ?? '')?.clamp(0, bytes.length - 1) ??
      bytes.length - 1;

  if (start > end) {
    response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
    response.headers.set(
      HttpHeaders.contentRangeHeader,
      'bytes */${bytes.length}',
    );
  } else {
    if (range != null) {
      response.statusCode = HttpStatus.partialContent;
      response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$end/${bytes.length}',
      );
    }
    response.contentLength = end - start + 1;
    if (request.method != 'HEAD') {
      response.add(bytes.sublist(start, end + 1));
    }
  }

  try {
    await response.close();
  } on SocketException {
    // Native players can cancel a range request when they have enough data.
  }
}
