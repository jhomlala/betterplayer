class ContentTypes {
  static const String audioContentType = 'audio';
  static const String videoContentType = 'video';
  static const String textContentType = 'text';

  static bool isAudio(String? contentType) =>
      contentType == null || contentType.isEmpty ? false : audioContentType == contentType;

  static bool isVideo(String? contentType) =>
      contentType == null || contentType.isEmpty ? false : videoContentType == contentType;

  static bool isText(String? contentType) =>
      contentType == null || contentType.isEmpty ? false : textContentType == contentType;
}
