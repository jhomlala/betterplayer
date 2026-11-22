import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_cast/src/config/cast_configuration.dart';
import 'package:better_player_cast/src/discovery/bonsoir_cast_discovery.dart';
import 'package:better_player_cast/src/discovery/cast_discovery.dart';
import 'package:better_player_cast/src/models/cast_device.dart';
import 'package:better_player_cast/src/models/cast_media_info.dart';
import 'package:better_player_cast/src/models/cast_media_status.dart';
import 'package:better_player_cast/src/models/cast_player_state.dart';
import 'package:better_player_cast/src/models/cast_session_state.dart';
import 'package:better_player_cast/src/protocol/cast_session.dart';
import 'package:better_player_cast/src/protocol/cast_socket.dart';
import 'package:better_player_cast/src/ui/cast_device_picker_sheet.dart';
import 'package:better_player_cast/src/ui/cast_player_overlay.dart';
import 'package:material_ui/material_ui.dart';

/// Chromecast extension for Better Player implementing [PlayerCastExtension].
class BetterPlayerCastExtension extends PlayerCastExtension {
  /// Creates a Better Player Cast extension.
  BetterPlayerCastExtension({
    this.navigatorKey,
    this.contextProvider,
    this.configuration = const CastConfiguration(),
    CastDiscovery? discovery,
    CastSocketFactory? socketFactory,
  }) : _discovery = discovery ?? BonsoirCastDiscovery(),
       _session = CastSession(
         configuration: configuration,
         socketFactory: socketFactory,
       );

  /// Navigator key used to obtain context for presenting the cast picker.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Optional function returning the build context for presenting the cast picker.
  final BuildContext? Function()? contextProvider;

  /// Cast configuration options.
  final CastConfiguration configuration;

  final CastDiscovery _discovery;
  final CastSession _session;

  BetterPlayerController? _controller;
  StreamSubscription<CastSessionState>? _sessionStateSubscription;
  StreamSubscription<CastMediaStatus>? _mediaStatusSubscription;
  final StreamController<bool> _castingStreamController =
      StreamController<bool>.broadcast();

  late final Widget _overlay = CastPlayerOverlay(
    castingStream: castingStream,
    isCastingProvider: () => isCasting,
    deviceNameProvider: () => targetDeviceName,
  );

  @override
  bool get isCasting => _session.isConnected;

  @override
  Stream<bool> get castingStream => _castingStreamController.stream;

  @override
  String? get targetDeviceName => _session.device?.name;

  @override
  Widget? get overlayWidget => _overlay;

  @override
  bool? get isRemotePlaying {
    if (!isCasting) return null;
    final status = _session.mediaStatus;
    if (status == null) return true;
    return status.playerState == CastPlayerState.playing;
  }

  @override
  bool? get isRemoteBuffering {
    if (!isCasting) return null;
    final state = _session.mediaStatus?.playerState;
    return state == CastPlayerState.buffering ||
        state == CastPlayerState.loading;
  }

  @override
  Duration? get remotePosition => isCasting ? _session.estimatedPosition : null;

  @override
  Duration? get remoteDuration =>
      isCasting ? _session.mediaStatus?.duration : null;

  @override
  double? get remoteVolume {
    if (!isCasting) return null;
    final status = _session.mediaStatus;
    if (status == null) return null;
    return status.muted ? 0.0 : status.volume;
  }

  /// Current active Cast session.
  CastSession get session => _session;

  /// Current active device discovery.
  CastDiscovery get discovery => _discovery;

  @override
  Future<bool> play() async {
    if (!isCasting) return false;
    await _session.play();
    return true;
  }

  @override
  Future<bool> pause() async {
    if (!isCasting) return false;
    await _session.pause();
    return true;
  }

  @override
  Future<bool> seekTo(Duration position) async {
    if (!isCasting) return false;
    await _session.seek(position);
    return true;
  }

  @override
  Future<bool> setVolume(double volume) async {
    if (!isCasting) return false;
    await _session.setVolume(volume, muted: volume == 0.0);
    return true;
  }

  @override
  void onAttach(BetterPlayerController controller) {
    _controller = controller;

    _sessionStateSubscription = _session.stateStream.listen(
      _onSessionStateChanged,
    );
    _mediaStatusSubscription = _session.mediaStatusStream.listen(
      _onMediaStatusChanged,
    );
    controller.addEventsListener(_onPlayerEvent);
  }

  @override
  void onDetach(BetterPlayerController controller) {
    controller.removeEventsListener(_onPlayerEvent);
    _sessionStateSubscription?.cancel();
    _mediaStatusSubscription?.cancel();
    unawaited(_session.dispose());
    unawaited(_discovery.dispose());
    if (!_castingStreamController.isClosed) {
      unawaited(_castingStreamController.close());
    }
    _controller = null;
  }

  @override
  Future<void> showCastPicker() async {
    final initialContext =
        contextProvider?.call() ??
        navigatorKey?.currentContext ??
        _controller?.betterPlayerGlobalKey?.currentContext;
    if (initialContext == null) {
      PlayerLogger.warning(
        message: 'Cannot show cast picker: BuildContext is null',
      );
      return;
    }

    try {
      await _discovery.start();
    } on Object catch (error) {
      PlayerLogger.warning(
        message: 'Cast discovery failed to start: $error',
      );
    }

    final context =
        contextProvider?.call() ??
        navigatorKey?.currentContext ??
        _controller?.betterPlayerGlobalKey?.currentContext;
    if (context == null || !context.mounted) {
      await _discovery.stop();
      return;
    }

    await _presentPickerSheet(context);
    await _discovery.stop();
  }

  Future<void> _presentPickerSheet(BuildContext context) {
    Widget buildSheetContent(BuildContext sheetContext) {
      return StreamBuilder<List<CastDevice>>(
        stream: _discovery.devicesStream,
        initialData: _discovery.devices,
        builder: (context, snapshot) {
          final devices = snapshot.data ?? const <CastDevice>[];
          return CastDevicePickerSheet(
            configuration: configuration,
            devices: devices,
            isScanning: _discovery.isScanning,
            connectedDevice: _session.device,
            onDeviceSelected: (device) {
              Navigator.of(sheetContext).pop();
              unawaited(_connectAndCast(device));
            },
            onDisconnect: () {
              Navigator.of(sheetContext).pop();
              unawaited(disconnect());
            },
          );
        },
      );
    }

    final hasMaterialLocalizations =
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        ) !=
        null;

    if (hasMaterialLocalizations) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: buildSheetContent,
      );
    }

    final useRootNavigator =
        _controller?.betterPlayerConfiguration.useRootNavigator ?? false;
    final navigator = Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    );
    const fallbackLocalizations = DefaultMaterialLocalizations();
    return navigator.push<void>(
      ModalBottomSheetRoute<void>(
        isScrollControlled: true,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        barrierLabel: fallbackLocalizations.scrimLabel,
        barrierOnTapHint: fallbackLocalizations.scrimOnTapHint(
          fallbackLocalizations.bottomSheetLabel,
        ),
        builder: (sheetContext) => Localizations.override(
          context: sheetContext,
          delegates: const [DefaultMaterialLocalizations.delegate],
          child: Builder(builder: buildSheetContent),
        ),
      ),
    );
  }

  /// Disconnects from the current Cast receiver and resumes local playback.
  Future<void> disconnect({bool stopReceiver = true}) async {
    if (!isCasting) return;

    final lastPosition =
        _session.estimatedPosition ?? _session.mediaStatus?.currentTime;
    if (stopReceiver) {
      try {
        await _session.stop();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } on Object catch (_) {}
    }
    await _session.disconnect();

    final controller = _controller;
    if (controller != null && lastPosition != null) {
      await controller.seekTo(lastPosition);
      await controller.play();
    }
  }

  Future<void> _connectAndCast(CastDevice device) async {
    final controller = _controller;
    final dataSource = controller?.betterPlayerDataSource;
    if (controller == null || dataSource == null) {
      PlayerLogger.warning(message: 'Cannot cast: no active data source');
      return;
    }

    if (dataSource.type == DataSourceType.file) {
      PlayerLogger.warning(
        message: 'Cannot cast local file data source to Chromecast directly',
      );
      return;
    }

    final currentPosition =
        controller.videoPlayerValue?.position ?? Duration.zero;

    await controller.pause();

    try {
      await _session.connect(device);

      final mediaInfo = _buildMediaInfo(dataSource);
      await _session.loadMedia(
        mediaInfo,
        startPosition: currentPosition,
      );
    } on Object catch (error) {
      PlayerLogger.error(message: 'Failed to cast to device: $error');
      await controller.play();
    }
  }

  CastMediaInfo _buildMediaInfo(PlayerDataSource dataSource) {
    return CastMediaInfo(
      url: dataSource.url,
      contentType: _inferContentType(dataSource),
      title: dataSource.notificationConfiguration?.title,
      subtitle: dataSource.notificationConfiguration?.author,
      imageUrl: dataSource.notificationConfiguration?.imageUrl,
      streamType: dataSource.liveStream == true ? 'LIVE' : 'BUFFERED',
    );
  }

  String _inferContentType(PlayerDataSource dataSource) {
    final path =
        Uri.tryParse(dataSource.url)?.path.toLowerCase() ??
        dataSource.url.toLowerCase();
    if (dataSource.videoFormat == VideoFormat.hls || path.endsWith('.m3u8')) {
      return 'application/x-mpegURL';
    }
    if (dataSource.videoFormat == VideoFormat.dash || path.endsWith('.mpd')) {
      return 'application/dash+xml';
    }
    if (path.endsWith('.webm')) {
      return 'video/webm';
    }
    return 'video/mp4';
  }

  void _onPlayerEvent(PlayerEvent event) {
    if (!isCasting) return;

    if (event.betterPlayerEventType == PlayerEventType.setupDataSource) {
      final ds = _controller?.betterPlayerDataSource;
      if (ds != null && ds.type != DataSourceType.file) {
        unawaited(_session.loadMedia(_buildMediaInfo(ds)));
      }
    }
  }

  void _onSessionStateChanged(CastSessionState state) {
    final casting = state == CastSessionState.connected;
    if (!_castingStreamController.isClosed) {
      _castingStreamController.add(casting);
    }
    _controller?.postEvent(
      PlayerEvent(PlayerEventType.externalPlaybackChanged),
    );
  }

  void _onMediaStatusChanged(CastMediaStatus status) {
    if (!_castingStreamController.isClosed) {
      _castingStreamController.add(isCasting);
    }
  }
}
