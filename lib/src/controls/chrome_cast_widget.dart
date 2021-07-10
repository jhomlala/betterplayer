
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
  ChromeCastButton(
      {Key? key,
        this.size = 30.0,
        this.color = Colors.black,
        this.onButtonCreated,
        this.onSessionStarted,
        this.onSessionEnded,
        this.onRequestCompleted,
        this.onRequestFailed}):
        super(key: key);

  /// The size of the button.
  final double size;

  /// The color of the button.
  /// This is only supported on iOS at the moment.
  final Color color;

  /// Callback method for when the button is ready to be used.
  ///
  /// Used to receive a [ChromeCastController] for this [ChromeCastButton].
  final OnButtonCreated? onButtonCreated;

  /// Called when a cast session has started.
  final VoidCallback? onSessionStarted;

  /// Called when a cast session has ended.
  final VoidCallback? onSessionEnded;

  /// Called when a cast request has successfully completed.
  final VoidCallback? onRequestCompleted;

  /// Called when a cast request has failed.
  final OnRequestFailed? onRequestFailed;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = <String,dynamic>{
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
    print("Init completed!!!!");
    if (onButtonCreated != null) {
      onButtonCreated?.call(controller);
    }
    if (onSessionStarted != null) {
      _chromeCastPlatform
          .onSessionStarted(id: id)
          .listen((_) => onSessionStarted?.call());
    }
    if (onSessionEnded != null) {
      _chromeCastPlatform
          .onSessionEnded(id: id)
          .listen((_) => onSessionEnded?.call());
    }
    if (onRequestCompleted != null) {
      _chromeCastPlatform
          .onRequestCompleted(id: id)
          .listen((_) => onRequestCompleted?.call());
    }
    if (onRequestFailed != null) {
      _chromeCastPlatform
          .onRequestFailed(id: id)
          .listen((event) => onRequestFailed?.call(event.error));
    }
  }
}


final ChromeCastPlatform _chromeCastPlatform = ChromeCastPlatform.instance;

/// Controller for a single ChromeCastButton instance running on the host platform.
class ChromeCastController {
  /// The id for this controller
  final int? id;

  ChromeCastController._({@required this.id});

  /// Initialize control of a [ChromeCastButton] with [id].
  static Future<ChromeCastController> init(int id) async {
    await _chromeCastPlatform.init(id);
    print("Done!!!");
    return ChromeCastController._(id: id);
  }

  /// Add listener for receive callbacks.
  Future<void> addSessionListener() {
    return _chromeCastPlatform.addSessionListener(id: id);
  }

  /// Remove listener for receive callbacks.
  Future<void> removeSessionListener() {
    return _chromeCastPlatform.removeSessionListener(id: id);
  }

  /// Load a new media by providing an [url].
  Future<void> loadMedia(String url) {
    return _chromeCastPlatform.loadMedia(url, id: id);
  }

  /// Plays the video playback.
  Future<void> play() {
    return _chromeCastPlatform.play(id: id);
  }

  /// Pauses the video playback.
  Future<void> pause() {
    return _chromeCastPlatform.pause(id: id);
  }

  /// If [relative] is set to false sets the video position to an [interval] from the start.
  ///
  /// If [relative] is set to true sets the video position to an [interval] from the current position.
  Future<void> seek({bool relative = false, double interval = 10.0}) {
    return _chromeCastPlatform.seek(relative, interval, id: id);
  }

  /// Stop the current video.
  Future<void> stop() {
    return _chromeCastPlatform.stop(id: id);
  }

  /// Returns `true` when a cast session is connected, `false` otherwise.
  Future<bool> isConnected() {
    return _chromeCastPlatform.isConnected(id: id);
  }

  /// Returns `true` when a cast session is playing, `false` otherwise.
  Future<bool> isPlaying() {
    return _chromeCastPlatform.isPlaying(id: id);
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

  /// Initializes the platform interface with [id].
  ///
  /// This method is called when the plugin is first initialized.
  Future<void> init(int id) {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Add listener for receive callbacks.
  Future<void> addSessionListener({@required int? id}) {
    throw UnimplementedError('addSessionListener() has not been implemented.');
  }

  /// Remove listener for receive callbacks.
  Future<void> removeSessionListener({@required int? id}) {
    throw UnimplementedError(
        'removeSessionListener() has not been implemented.');
  }

  /// A session is started.
  Stream<SessionStartedEvent> onSessionStarted({@required int? id}) {
    throw UnimplementedError('onSessionStarted() has not been implemented.');
  }

  /// A session is ended.
  Stream<SessionEndedEvent> onSessionEnded({@required int? id}) {
    throw UnimplementedError('onSessionEnded() has not been implemented.');
  }

  /// A request has completed.
  Stream<RequestDidCompleteEvent> onRequestCompleted({@required int? id}) {
    throw UnimplementedError('onRequestCompleted() has not been implemented.');
  }

  /// A request has failed.
  Stream<RequestDidFailEvent> onRequestFailed({@required int? id}) {
    throw UnimplementedError('onSessionEnded() has not been implemented.');
  }

  /// Load a new media by providing an [url].
  Future<void> loadMedia(
      String url, {
        @required int? id,
      }) {
    throw UnimplementedError('loadMedia() has not been implemented.');
  }

  /// Plays the video playback.
  Future<void> play({@required int? id}) {
    throw UnimplementedError('play() has not been implemented.');
  }

  /// Pauses the video playback.
  Future<void> pause({@required int? id}) {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// If [relative] is set to false sets the video position to an [interval] from the start.
  ///
  /// If [relative] is set to true sets the video position to an [interval] from the current position.
  Future<void> seek(bool relative, double interval, {@required int? id}) {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Stop the current video.
  Future<void> stop({@required int? id}) {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Returns `true` when a cast session is connected, `false` otherwise.
  Future<bool> isConnected({@required int? id}) {
    throw UnimplementedError('seek() has not been implemented.');
  }

  /// Returns `true` when a cast session is playing, `false` otherwise.
  Future<bool> isPlaying({@required int? id}) {
    throw UnimplementedError('isPlaying() has not been implemented.');
  }

  /// Returns a widget displaying the button.
  Widget buildView(Map<String, dynamic> arguments,
      PlatformViewCreatedCallback onPlatformViewCreated) {
    throw UnimplementedError('buildView() has not been implemented.');
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

  // The controller we need to broadcast the different events coming
  // from handleMethodCall.
  //
  // It is a `broadcast` because multiple controllers will connect to
  // different stream views of this Controller.
  final StreamController<ChromeCastEvent> _eventStreamController = StreamController<ChromeCastEvent>.broadcast();

  // Returns a filtered view of the events in the _controller, by id.
  Stream<ChromeCastEvent> _events(int id) =>
      _eventStreamController.stream.where((event) => event.id == id);

  @override
  Future<void> init(int id) {
    MethodChannel? channel = null;
    if (!_channels.containsKey(id)) {
      channel = MethodChannel('flutter_video_cast/chromeCast_$id');
      channel.setMethodCallHandler((call) => _handleMethodCall(call, id));
      _channels[id] = channel;
    }
    print("here completed");
    return channel!.invokeMethod<void>('chromeCast#wait');
  }

  @override
  Future<void> addSessionListener({int? id}) {
    return channel(id).invokeMethod<void>('chromeCast#addSessionListener');
  }

  @override
  Future<void> removeSessionListener({int? id}) {
    return channel(id).invokeMethod<void>('chromeCast#removeSessionListener');
  }

  @override
  Stream<SessionStartedEvent> onSessionStarted({int? id}) {
    return _events(id!).where((element) => element is SessionStartedEvent) as Stream<SessionStartedEvent>;

  }

  @override
  Stream<SessionEndedEvent> onSessionEnded({int? id}) {
    return _events(id!).where((element) => element is SessionEndedEvent) as Stream<SessionEndedEvent>;
  }

  @override
  Stream<RequestDidCompleteEvent> onRequestCompleted({int? id}) {
    return _events(id!).where((element) => element is RequestDidCompleteEvent) as Stream<RequestDidCompleteEvent>;
  }

  @override
  Stream<RequestDidFailEvent> onRequestFailed({int? id}) {
    return _events(id!).where((element) => element is RequestDidFailEvent) as Stream<RequestDidFailEvent>;
  }

  @override
  Future<void> loadMedia(String url, {@required int? id}) {
    final Map<String, dynamic> args = <String,dynamic>{'url': url};
    return channel(id).invokeMethod<void>('chromeCast#loadMedia', args);
  }

  @override
  Future<void> play({@required int? id}) {
    return channel(id).invokeMethod<void>('chromeCast#play');
  }

  @override
  Future<void> pause({@required int? id}) {
    return channel(id).invokeMethod<void>('chromeCast#pause');
  }

  @override
  Future<void> seek(bool relative, double interval, {@required int ?id}) {
    final Map<String, dynamic> args = <String,dynamic>{
      'relative': relative,
      'interval': interval
    };
    return channel(id).invokeMethod<void>('chromeCast#seek', args);
  }

  @override
  Future<void> stop({int? id}) {
    return channel(id).invokeMethod<void>('chromeCast#stop');
  }

  @override
  Future<bool> isConnected({@required int? id}) {
    return channel(id!).invokeMethod<bool>('chromeCast#isConnected') as Future<bool>;
  }

  @override
  Future<bool> isPlaying({@required int? id}) {
    return channel(id!).invokeMethod<bool>('chromeCast#isPlaying') as Future<bool>;
  }

  @override
  Future<void> click({int? id}) {
    return channel(id).invokeMethod<void>('chromeCast#click');
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int id) async {
    switch (call.method) {
      case 'chromeCast#didStartSession':
        _eventStreamController.add(SessionStartedEvent(id));
        break;
      case 'chromeCast#didEndSession':
        _eventStreamController.add(SessionEndedEvent(id));
        break;
      case 'chromeCast#requestDidComplete':
        _eventStreamController.add(RequestDidCompleteEvent(id));
        break;
      case 'chromeCast#requestDidFail':
        _eventStreamController
            .add(RequestDidFailEvent(id, call.arguments['error']));
        break;
      default:
        throw MissingPluginException();
    }
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

/// Generic Event coming from the native side.
///
/// All ChromeCastEvents contain the `id` that originated the event. This should
/// never be `null`.
class ChromeCastEvent {
  /// The ID of the button this event is associated to.
  final int id;

  /// Build a ChromeCast Event, that relates a id with a given value.
  ///
  /// The `id` is the id of the button that triggered the event.
  ChromeCastEvent(this.id);
}

/// An event fired when a session of a [id] started.
class SessionStartedEvent extends ChromeCastEvent {
  /// Build a SessionStarted Event triggered from the button represented by `id`.
  SessionStartedEvent(int id) : super(id);
}

/// An event fired when a session of a [id] ended.
class SessionEndedEvent extends ChromeCastEvent {
  /// Build a SessionEnded Event triggered from the button represented by `id`.
  SessionEndedEvent(int id) : super(id);
}

/// An event fired when a request of a [id] completed.
class RequestDidCompleteEvent extends ChromeCastEvent {
  /// Build a RequestDidComplete Event triggered from the button represented by `id`.
  RequestDidCompleteEvent(int id) : super(id);
}

/// An event fired when a request of a [id] failed.
class RequestDidFailEvent extends ChromeCastEvent {
  /// The error message.
  final String error;

  /// Build a RequestDidFail Event triggered from the button represented by `id`.
  RequestDidFailEvent(int id, this.error) : super(id);
}