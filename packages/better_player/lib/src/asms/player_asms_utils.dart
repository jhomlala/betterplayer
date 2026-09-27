import 'dart:convert';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/dash/player_dash_utils.dart';
import 'package:better_player/src/hls/player_hls_utils.dart';
import 'package:better_player/src/logging/player_logger.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

///Base helper class for ASMS parsing.
class PlayerAsmsUtils {
  PlayerAsmsUtils({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const String _hlsExtension = 'm3u8';
  static const String _dashExtension = 'mpd';

  ///Check if given url is HLS / DASH-type data source.
  bool isDataSourceAsms(String url) =>
      isDataSourceHls(url) || isDataSourceDash(url);

  ///Check if given url is HLS-type data source.
  bool isDataSourceHls(String url) => url.contains(_hlsExtension);

  ///Check if given url is DASH-type data source.
  bool isDataSourceDash(String url) => url.contains(_dashExtension);

  ///Parse playlist based on type of stream.
  Future<PlayerAsmsDataHolder> parse(
    String data,
    String masterPlaylistUrl, {
    Map<String, String?>? headers,
  }) async {
    return isDataSourceDash(masterPlaylistUrl)
        ? PlayerDashUtils.parse(data, masterPlaylistUrl)
        : PlayerHlsUtils(httpClient: _httpClient).parse(
            data,
            masterPlaylistUrl,
            headers: headers,
          );
  }

  ///Request data from given uri along with headers. May return null if resource
  ///is not available or on error.
  Future<String?> getDataFromUrl(
    String url, [
    Map<String, String?>? headers,
  ]) async {
    final result = await getDataWithRedirectUrl(url, headers);
    return result.data;
  }

  ///Request data from given uri along with headers and return the final
  ///effective URL after any HTTP redirects.
  Future<({String? data, String effectiveUrl})> getDataWithRedirectUrl(
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
        final effectiveUrl = response.request?.url.toString() ?? url;
        return (data: response.body, effectiveUrl: effectiveUrl);
      } else {
        PlayerLogger.error(
          message: 'GetDataFromUrl failed: HTTP status ${response.statusCode}',
        );
        return (data: null, effectiveUrl: url);
      }
    } catch (exception) {
      PlayerLogger.error(
        message: 'GetDataFromUrl failed: $exception',
        error: exception,
      );
      return (data: null, effectiveUrl: url);
    }
  }
}
