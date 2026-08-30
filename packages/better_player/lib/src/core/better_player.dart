import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/player_controller_event.dart';
import 'package:better_player/src/core/better_player_full_screen_video.dart';
import 'package:better_player/src/core/better_player_logger.dart';
import 'package:better_player/src/core/better_player_with_controls.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

///Widget which uses provided controller to render video player.
class BetterPlayer extends StatefulWidget {
  const BetterPlayer({required this.controller, super.key});

  factory BetterPlayer.network(
    String url, {
    PlayerConfiguration? betterPlayerConfiguration,
  }) => BetterPlayer(
    controller: BetterPlayerController(
      betterPlayerConfiguration ?? const PlayerConfiguration(),
      betterPlayerDataSource: PlayerDataSource(
        DataSourceType.network,
        url,
      ),
    ),
  );

  factory BetterPlayer.file(
    String url, {
    PlayerConfiguration? betterPlayerConfiguration,
  }) => BetterPlayer(
    controller: BetterPlayerController(
      betterPlayerConfiguration ?? const PlayerConfiguration(),
      betterPlayerDataSource: PlayerDataSource(
        DataSourceType.file,
        url,
      ),
    ),
  );

  final BetterPlayerController controller;

  @override
  _BetterPlayerState createState() {
    return _BetterPlayerState();
  }
}

class _BetterPlayerState extends State<BetterPlayer>
    with WidgetsBindingObserver {
  PlayerConfiguration get _betterPlayerConfiguration =>
      widget.controller.betterPlayerConfiguration;

  bool _isFullScreen = false;

  ///State of navigator on widget created
  late NavigatorState _navigatorState;

  ///Flag which determines if widget has initialized
  bool _initialized = false;

  ///Subscription for controller events
  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    if (!_initialized) {
      final navigator = Navigator.of(context);
      setState(() {
        _navigatorState = navigator;
      });
      _setup();
      _initialized = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _setup() async {
    _controllerEventSubscription = widget.controller.controllerEventStream
        .listen(onControllerEvent);

    //Default locale
    var locale = const Locale('en', 'US');
    try {
      if (mounted) {
        final contextLocale = Localizations.localeOf(context);
        locale = contextLocale;
      }
    } catch (exception) {
      BPLog.error(
        'Failed to get locale: $exception',
        error: exception,
        breadcrumb: 'BetterPlayer',
      );
    }
    widget.controller.setupTranslations(locale);
  }

  @override
  void dispose() {
    ///If somehow BetterPlayer widget has been disposed from widget tree and
    ///full screen is on, then full screen route must be pop and return to normal
    ///state.
    if (_isFullScreen) {
      WakelockPlus.disable();
      _navigatorState.maybePop();
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: _betterPlayerConfiguration.systemOverlaysAfterFullScreen,
      );
      SystemChrome.setPreferredOrientations(
        _betterPlayerConfiguration.deviceOrientationsAfterFullScreen,
      );
    }

    WidgetsBinding.instance.removeObserver(this);
    _controllerEventSubscription?.cancel();
    widget.controller.dispose();
    VisibilityDetectorController.instance.forget(
      Key('${widget.controller.hashCode}_key'),
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(BetterPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription = widget.controller.controllerEventStream
          .listen(onControllerEvent);
    }
    super.didUpdateWidget(oldWidget);
  }

  void onControllerEvent(PlayerControllerEvent event) {
    switch (event) {
      case PlayerControllerEvent.openFullscreen:
        onFullScreenChanged();
      case PlayerControllerEvent.hideFullscreen:
        onFullScreenChanged();
      default:
        setState(() {});
    }
  }

  Future<void> onFullScreenChanged() async {
    final controller = widget.controller;
    if (controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      controller.postEvent(
        PlayerEvent(PlayerEventType.openFullscreen),
      );
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isFullScreen = false;
      controller.postEvent(
        PlayerEvent(PlayerEventType.hideFullscreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BetterPlayerControllerProvider(
      controller: widget.controller,
      child: _BetterPlayerVideoWithVisibility(controller: widget.controller),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    BetterPlayerControllerProvider controllerProvider,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return BetterPlayerFullScreenVideo(
          controllerProvider: controllerProvider,
        );
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = BetterPlayerControllerProvider(
      controller: widget.controller,
      child: _BetterPlayerVideoWithVisibility(controller: widget.controller),
    );

    final routePageBuilder = _betterPlayerConfiguration.routePageBuilder;
    if (routePageBuilder == null) {
      return _defaultRoutePageBuilder(
        context,
        animation,
        secondaryAnimation,
        controllerProvider,
      );
    }

    return routePageBuilder(
      context,
      animation,
      secondaryAnimation,
      controllerProvider,
    );
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (_betterPlayerConfiguration.autoDetectFullscreenDeviceOrientation) {
      final aspectRatio =
          widget.controller.videoPlayerController?.value.aspectRatio ?? 1.0;
      List<DeviceOrientation> deviceOrientations;
      if (aspectRatio < 1.0) {
        deviceOrientations = [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ];
      } else {
        deviceOrientations = [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ];
      }
      await SystemChrome.setPreferredOrientations(deviceOrientations);
    } else {
      await SystemChrome.setPreferredOrientations(
        widget
            .controller
            .betterPlayerConfiguration
            .deviceOrientationsOnFullScreen,
      );
    }

    if (!_betterPlayerConfiguration.allowedScreenSleep) {
      WakelockPlus.enable();
    }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    WakelockPlus.disable();

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: _betterPlayerConfiguration.systemOverlaysAfterFullScreen,
    );
    await SystemChrome.setPreferredOrientations(
      _betterPlayerConfiguration.deviceOrientationsAfterFullScreen,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    widget.controller.setAppLifecycleState(state);
  }
}

class _BetterPlayerVideoWithVisibility extends StatelessWidget {
  const _BetterPlayerVideoWithVisibility({required this.controller});
  final BetterPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('${controller.hashCode}_key'),
      onVisibilityChanged: (info) =>
          controller.onPlayerVisibilityChanged(info.visibleFraction),
      child: BetterPlayerWithControls(controller: controller),
    );
  }
}

///Page route builder used in fullscreen mode.
typedef BetterPlayerRoutePageBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      BetterPlayerControllerProvider controllerProvider,
    );
