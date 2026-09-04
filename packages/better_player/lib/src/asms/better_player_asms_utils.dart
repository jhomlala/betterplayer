import 'dart:convert';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/dash/better_player_dash_utils.dart';
import 'package:better_player/src/hls/better_player_hls_utils.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:http/http.dart' as http;

///Base helper class for ASMS parsing.
class BetterPlayerAsmsUtils {
  static const String _hlsExtension = 'm3u8';
  static const String _dashExtension = 'mpd';

  static http.Client? _httpClientCache;
  static http.Client get _httpClient {
    _httpClientCache ??= http.Client();
    return _httpClientCache!;
  }

  ///Check if given url is HLS / DASH-type data source.
  static bool isDataSourceAsms(String url) =>
      isDataSourceHls(url) || isDataSourceDash(url);

  ///Check if given url is HLS-type data source.
  static bool isDataSourceHls(String url) => url.contains(_hlsExtension);

  ///Check if given url is DASH-type data source.
  static bool isDataSourceDash(String url) => url.contains(_dashExtension);

  ///Parse playlist based on type of stream.
  static Future<PlayerAsmsDataHolder> parse(
    String data,
    String masterPlaylistUrl,
  ) async {
    return isDataSourceDash(masterPlaylistUrl)
        ? BetterPlayerDashUtils.parse(data, masterPlaylistUrl)
        : BetterPlayerHlsUtils.parse(data, masterPlaylistUrl);
  }

  ///Request data from given uri along with headers. May return null if resource
  ///is not available or on error.
  static Future<String?> getDataFromUrl(
    String url, [
    Map<String, String?>? headers,
  ]) async {
    try {
      final nonNullHeaders = <String, String>{};
      if (headers != null) {
        headers.forEach((key, value) {
          if (value != null) {
            nonNullHeaders[key] = value;
          }
        });
      }

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: nonNullHeaders.isEmpty ? null : nonNullHeaders,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        PlayerLogger.error(
          message: 'GetDataFromUrl failed: HTTP status ${response.statusCode}',
        );
        return null;
      }
    } catch (exception) {
      PlayerLogger.error(
        message: 'GetDataFromUrl failed: $exception',
        error: exception,
      );
      return null;
    }
  }
}
