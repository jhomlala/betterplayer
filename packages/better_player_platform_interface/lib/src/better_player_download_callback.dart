import 'package:better_player_platform_interface/src/models/download_state.dart';

/// Receives the state changes of the media downloads.
///
/// The callback is the sibling of the download progress stream. Use it when
/// the caller only needs the state and the error of each download.
// A named contract keeps the public API stable when a later version adds a
// member. A function typedef cannot grow.
// ignore: one_member_abstracts
abstract class BetterPlayerDownloadCallback {
  /// Creates a callback that receives the download state changes.
  const BetterPlayerDownloadCallback();

  /// Called when the download of [url] moves to [state].
  ///
  /// [error] carries the message when [state] is [DownloadState.failed], and
  /// is `null` otherwise.
  void onDownloadState(String url, DownloadState state, String? error);
}
