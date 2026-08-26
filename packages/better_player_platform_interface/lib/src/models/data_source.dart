import 'package:better_player_platform_interface/src/models/cache_configuration.dart';
import 'package:better_player_platform_interface/src/models/data_source_type.dart';
import 'package:better_player_platform_interface/src/models/drm_configuration.dart';
import 'package:better_player_platform_interface/src/models/notification_configuration.dart';
import 'package:better_player_platform_interface/src/models/video_format.dart';

/// Description of the data source used to create an instance of
/// the video player.
class DataSource {
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
    this.cacheConfiguration,
    this.notificationConfiguration,
    this.drmConfiguration,
    this.overriddenDuration,
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

  final CacheConfiguration? cacheConfiguration;

  final NotificationConfiguration? notificationConfiguration;

  final DrmConfiguration? drmConfiguration;

  final Duration? overriddenDuration;

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
    return 'DataSource{sourceType: $sourceType, uri: $uri, formatHint: $formatHint, '
        'asset: $asset, package: $package, headers: $headers, '
        'cacheConfiguration: $cacheConfiguration, notificationConfiguration: $notificationConfiguration, '
        'drmConfiguration: $drmConfiguration}';
  }
}
