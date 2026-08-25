import 'package:better_player_platform_interface/src/models/data_source_type.dart';
import 'package:better_player_platform_interface/src/models/video_format.dart';

/// Description of the data source used to create an instance of
/// the video player.
class DataSource {
  /// The maximum cache size to keep on disk in bytes.
  static const int _maxCacheSize = 100 * 1024 * 1024;

  /// The maximum size of each individual file in bytes.
  static const int _maxCacheFileSize = 10 * 1024 * 1024;

  /// Constructs an instance of [DataSource].
  ///
  /// The [sourceType] is always required.
  ///
  /// The [uri] argument takes the form of `'https://example.com/video.mp4'` or
  /// `'file://${file.path}'`.
  ///
  /// The [formatHint] argument can be null.
  ///
  /// The [asset] argument takes the form of `'assets/video.mp4'`.
  ///
  /// The [package] argument must be non-null when the asset comes from a
  /// package and null otherwise.
  ///
  DataSource({
    required this.sourceType,
    this.uri,
    this.formatHint,
    this.asset,
    this.package,
    this.headers,
    this.useCache = false,
    this.maxCacheSize = _maxCacheSize,
    this.maxCacheFileSize = _maxCacheFileSize,
    this.cacheKey,
    this.showNotification = false,
    this.title,
    this.author,
    this.imageUrl,
    this.notificationChannelName,
    this.overriddenDuration,
    this.licenseUrl,
    this.certificateUrl,
    this.drmHeaders,
    this.activityName,
    this.clearKey,
    this.videoExtension,
  }) : assert(uri == null || asset == null);

  /// Describes the type of data source this [VideoPlayerController]
  /// is constructed with.
  ///
  /// The way in which the video was originally loaded.
  ///
  /// This has nothing to do with the video's file type. It's just the place
  /// from which the video is fetched from.
  final DataSourceType sourceType;

  /// The URI to the video file.
  ///
  /// This will be in different formats depending on the [DataSourceType] of
  /// the original video.
  final String? uri;

  /// **Android only**. Will override the platform's generic file format
  /// detection with whatever is set here.
  final VideoFormat? formatHint;

  /// **Android only**. String representation of a formatHint.
  String? get rawFormalHint {
    switch (formatHint) {
      case VideoFormat.ss:
        return 'ss';
      case VideoFormat.hls:
        return 'hls';
      case VideoFormat.dash:
        return 'dash';
      case VideoFormat.other:
        return 'other';
      default:
        return null;
    }
  }

  /// The name of the asset. Only set for [DataSourceType.asset] videos.
  final String? asset;

  /// The package that the asset was loaded from. Only set for
  /// [DataSourceType.asset] videos.
  final String? package;

  final Map<String, String?>? headers;

  final bool useCache;

  final int? maxCacheSize;

  final int? maxCacheFileSize;

  final String? cacheKey;

  final bool? showNotification;

  final String? title;

  final String? author;

  final String? imageUrl;

  final String? notificationChannelName;

  final Duration? overriddenDuration;

  final String? licenseUrl;

  final String? certificateUrl;

  final Map<String, String>? drmHeaders;

  final String? activityName;

  final String? clearKey;

  final String? videoExtension;

  /// Key to compare DataSource
  String get key {
    String? result = '';

    if (uri != null && uri!.isNotEmpty) {
      result = uri;
    } else if (package != null && package!.isNotEmpty) {
      result = '$package:$asset';
    } else {
      result = asset;
    }

    if (formatHint != null) {
      result = '$result:$rawFormalHint';
    }

    return result!;
  }

  @override
  String toString() {
    return 'DataSource{sourceType: $sourceType, uri: $uri certificateUrl: $certificateUrl, formatHint:'
        ' $formatHint, asset: $asset, package: $package, headers: $headers,'
        ' useCache: $useCache,maxCacheSize: $maxCacheSize, maxCacheFileSize: '
        '$maxCacheFileSize, showNotification: $showNotification, title: $title,'
        ' author: $author}';
  }
}
