import 'dart:async';
import 'dart:io';

import 'package:better_player/src/better_player_controller.dart';
import 'package:better_player/src/better_player_controller_provider.dart';
import 'package:better_player/src/better_player_data_source.dart';
import 'package:better_player/src/better_player_with_controls.dart';
import 'package:better_player/src/subtitles/better_player_subtitle.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:wakelock/wakelock.dart';

typedef Widget BetterPlayerRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    BetterPlayerControllerProvider controllerProvider);

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class BetterPlayer extends StatefulWidget {
  BetterPlayer({
    Key key,
    this.controller,
    this.betterPlayerDataSource,
  })  : assert(controller != null, 'You must provide a chewie controller'),
        super(key: key);

  /// The [BetterPlayerController]
  final BetterPlayerController controller;

  final BetterPlayerDataSource betterPlayerDataSource;

  @override
  BetterPlayerState createState() {
    return BetterPlayerState();
  }
}

class BetterPlayerState extends State<BetterPlayer> {
  BetterPlayerDataSource get betterPlayerDataSource =>
      widget.betterPlayerDataSource;

  bool _isFullScreen = false;
  DateTime dateTime;
  List<BetterPlayerSubtitle> subtitles;
  bool _setupComplete = false;

  @override
  void initState() {
    print("Better player init state");
    super.initState();
    widget.controller.addListener(listener);
  }

  void _setup() async {
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    print("Dispose $hashCode");
    widget.controller.removeListener(listener);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BetterPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      print("Did update add listener");
      widget.controller.addListener(listener);
      //oldWidget.controller.removeListener(listener);
      //oldWidget.controller.dispose();
      //print("Widget has changed!");
      // _setup();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _parseSubtitles() {
    try {
      File file = betterPlayerDataSource.subtitlesFile;
      if (file.existsSync()) {
        String fileContent = file.readAsStringSync();
        if (fileContent?.isNotEmpty == true) {
          subtitles =
              BetterPlayerSubtitlesParser.parseString(file.readAsStringSync());
        } else {
          subtitles = List();
        }
      } else {
        print("${betterPlayerDataSource.subtitlesFile} doesn't exist!");
      }
    } catch (exception) {
      print(
          "Failed to read subtitles from file: ${betterPlayerDataSource.subtitlesFile}: $exception");
    }
  }

  void listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isFullScreen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetterPlayerControllerProvider(
        controller: widget.controller, child: _buildPlayer());
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      BetterPlayerControllerProvider controllerProvider) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      BetterPlayerControllerProvider controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var controllerProvider = BetterPlayerControllerProvider(
        controller: widget.controller, child: _buildPlayer());

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(
          context, animation, secondaryAnimation, controllerProvider);
    }
    return widget.controller.routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    print("Push full screen");
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(),
      pageBuilder: _fullScreenRoutePageBuilder,
      opaque: true,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    if (!widget.controller.allowedScreenSleep) {
      Wakelock.enable();
    }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    Wakelock.disable();

    SystemChrome.setEnabledSystemUIOverlays(
        widget.controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsAfterFullScreen);
  }

  Widget _buildPlayer() {
    return BetterPlayerWithControls(
      subtitles: subtitles,
      subtitlesConfiguration:
      widget.controller.betterPlayerSettings.subtitlesConfiguration,
      controlsConfiguration:
      widget.controller.betterPlayerSettings.controlsConfiguration,
    );
  }

}
