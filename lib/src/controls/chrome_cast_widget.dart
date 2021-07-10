import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callback method for when the button is ready to be used.
///
/// Pass to [ChromeCastButton.onButtonCreated] to receive a [ChromeCastController]
/// when the button is created.
typedef void OnButtonCreated(ChromeCastController controller);

/// Callback method for when a request has failed.
typedef void OnRequestFailed(String error);

/// Widget that displays the ChromeCast button.
class ChromeCastButton extends StatelessWidget {
  /// Creates a widget displaying a ChromeCast button.
  ChromeCastButton({
    Key? key,
    this.size = 30.0,
    this.color = Colors.black,
    this.onButtonCreated,
  }) : super(key: key);

  /// The size of the button.
  final double size;

  /// The color of the button.
  /// This is only supported on iOS at the moment.
  final Color color;

  /// Callback method for when the button is ready to be used.
  ///
  /// Used to receive a [ChromeCastController] for this [ChromeCastButton].
  final OnButtonCreated? onButtonCreated;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = <String, dynamic>{
      'red': color.red,
      'green': color.green,
      'blue': color.blue,
      'alpha': color.alpha
    };
    return SizedBox(
      width: size,
      height: size,
      child: _chromeCastPlatform.buildView(args, _onPlatformViewCreated),
    );
  }

  Future<void> _onPlatformViewCreated(int id) async {
    print("On platform view created!");
    final ChromeCastController controller = await ChromeCastController.init(id);
    if (onButtonCreated != null) {
      onButtonCreated?.call(controller);
    }
  }
}

final ChromeCastPlatform _chromeCastPlatform = ChromeCastPlatform.instance;

/// Controller for a single ChromeCastButton instance running on the host platform.
class ChromeCastController {
  /// The id for this controller
  final int? id;

  ChromeCastController._({@required this.id});

  static Future<ChromeCastController> init(int id) async {
    await _chromeCastPlatform.init(id);
    print("Done!!!");
    return ChromeCastController._(id: id);
  }

  /// Stop the current video.
  Future<void> click() {
    return _chromeCastPlatform.click(id: id);
  }
}

/// The interface that platform-specific implementations of `flutter_video_cast` must extend.
abstract class ChromeCastPlatform {
  static ChromeCastPlatform _instance = MethodChannelChromeCast();

  /// The default instance of [ChromeCastPlatform] to use.
  ///
  /// Defaults to [MethodChannelChromeCast].
  static ChromeCastPlatform get instance => _instance;

  /// Returns a widget displaying the button.
  Widget buildView(Map<String, dynamic> arguments,
      PlatformViewCreatedCallback onPlatformViewCreated) {
    throw UnimplementedError('buildView() has not been implemented.');
  }

  /// Initializes the platform interface with [id].
  ///
  /// This method is called when the plugin is first initialized.
  Future<void> init(int id) {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Stop the current video.
  Future<void> click({@required int? id}) {
    throw UnimplementedError('click() has not been implemented.');
  }
}

/// An implementation of [ChromeCastPlatform] that uses [MethodChannel] to communicate with the native code.
class MethodChannelChromeCast extends ChromeCastPlatform {
  // Keep a collection of id -> channel
  // Every method call passes the int id
  final Map<int, MethodChannel> _channels = {};

  /// Accesses the MethodChannel associated to the passed id.
  MethodChannel channel(int? id) {
    return _channels[id]!;
  }

  @override
  Future<void> init(int id) async {
    MethodChannel? channel = null;
    if (!_channels.containsKey(id)) {
      channel = MethodChannel('flutter_video_cast/chromeCast_$id');
      _channels[id] = channel;
    }
    print("here completed");
  }

  @override
  Future<void> click({int? id}) {
    return channel(id).invokeMethod<void>('chromeCast#click');
  }

  @override
  Widget buildView(Map<String, dynamic> arguments,
      PlatformViewCreatedCallback onPlatformViewCreated) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'ChromeCastButton',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: arguments,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Text('is not supported by ChromeCast plugin');
  }
}
