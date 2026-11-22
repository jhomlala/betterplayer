import 'package:meta/meta.dart';

/// Describes media to be loaded onto a Cast receiver.
@immutable
class CastMediaInfo {
  /// Creates a Cast media description.
  const CastMediaInfo({
    required this.url,
    this.contentType = 'video/mp4',
    this.title,
    this.subtitle,
    this.imageUrl,
    this.streamType = 'BUFFERED',
    this.customData,
  });

  /// Direct URL of the media stream (must be reachable by the Cast receiver).
  final String url;

  /// MIME type of the media (e.g. "application/x-mpegURL", "video/mp4").
  final String contentType;

  /// Title displayed in the receiver UI.
  final String? title;

  /// Subtitle or artist displayed in the receiver UI.
  final String? subtitle;

  /// Poster image URL displayed in the receiver UI.
  final String? imageUrl;

  /// Stream type: "BUFFERED" for VOD or "LIVE" for live streams.
  final String streamType;

  /// Optional custom parameters passed to custom receiver applications.
  final Map<String, dynamic>? customData;

  /// Converts this media info into a CastV2 LOAD command media JSON payload.
  Map<String, dynamic> toJson() {
    final metadata = <String, dynamic>{
      'metadataType': 0,
    };
    if (title != null) metadata['title'] = title;
    if (subtitle != null) metadata['subtitle'] = subtitle;
    if (imageUrl != null) {
      metadata['images'] = [
        {'url': imageUrl},
      ];
    }

    final json = <String, dynamic>{
      'contentId': url,
      'streamType': streamType,
      'contentType': contentType,
      'metadata': metadata,
    };
    if (customData != null) {
      json['customData'] = customData;
    }
    return json;
  }
}
