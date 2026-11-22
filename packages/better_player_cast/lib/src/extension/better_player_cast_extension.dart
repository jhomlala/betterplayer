import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_cast/src/config/cast_configuration.dart';
import 'package:better_player_cast/src/discovery/bonsoir_cast_discovery.dart';
import 'package:better_player_cast/src/discovery/cast_discovery.dart';
import 'package:better_player_cast/src/models/cast_device.dart';
import 'package:better_player_cast/src/models/cast_media_info.dart';
import 'package:better_player_cast/src/models/cast_media_status.dart';
import 'package:better_player_cast/src/models/cast_session_state.dart';
import 'package:better_player_cast/src/protocol/cast_session.dart';
import 'package:better_player_cast/src/protocol/cast_socket.dart';
import 'package:better_player_cast/src/ui/cast_device_picker_sheet.dart';
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

  bool _isSyncing = false;

  @override
  bool get isCasting => _session.isConnected;

  @override
  Stream<bool> get castingStream => _castingStreamController.stream;

  @override
  String? get targetDeviceName => _session.device?.name;

  /// Current active Cast session.
  CastSession get session => _session;

  /// Current active device discovery.
  CastDiscovery get discovery => _discovery;

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
    _session.disconnect();
    _discovery.dispose();
    _castingStreamController.close();
    _controller = null;
  }

  @override
  Future<void> showCastPicker() async {
    final context = contextProvider?.call() ?? navigatorKey?.currentContext;
    if (context == null) {
      PlayerLogger.warning(
        message: 'Cannot show cast picker: BuildContext is null',
      );
      return;
    }

    await _discovery.start();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                _connectAndCast(device);
              },
              onDisconnect: () {
                Navigator.of(sheetContext).pop();
                disconnect();
              },
            );
          },
        );
      },
    );

    await _discovery.stop();
  }

  /// Disconnects from the current Cast receiver and resumes local playback.
  Future<void> disconnect({bool stopReceiver = true}) async {
    if (!isCasting) return;

    final lastPosition = _session.mediaStatus?.currentTime;
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
    if (dataSource.videoFormat == VideoFormat.hls ||
        dataSource.url.contains('.m3u8')) {
      return 'application/x-mpegURL';
    }
    if (dataSource.videoFormat == VideoFormat.dash ||
        dataSource.url.contains('.mpd')) {
      return 'application/dash+xml';
    }
    if (dataSource.url.endsWith('.webm')) {
      return 'video/webm';
    }
    return 'video/mp4';
  }

  void _onPlayerEvent(PlayerEvent event) {
    if (!isCasting || _isSyncing) return;

    final type = event.betterPlayerEventType;
    if (type == PlayerEventType.play) {
      _controller?.pause();
      _session.play();
    } else if (type == PlayerEventType.pause) {
      _session.pause();
    } else if (type == PlayerEventType.seekTo) {
      final duration = event.parameters?['duration'] as Duration?;
      if (duration != null) {
        _session.seek(duration);
      }
    } else if (type == PlayerEventType.setVolume) {
      final volume = event.parameters?['volume'] as double?;
      if (volume != null) {
        _session.setVolume(volume);
      }
    } else if (type == PlayerEventType.setupDataSource) {
      final ds = _controller?.betterPlayerDataSource;
      if (ds != null && ds.type != DataSourceType.file) {
        _session.loadMedia(_buildMediaInfo(ds));
      }
    }
  }

  void _onSessionStateChanged(CastSessionState state) {
    final casting = state == CastSessionState.connected;
    _castingStreamController.add(casting);
    _controller?.postEvent(
      PlayerEvent(PlayerEventType.externalPlaybackChanged),
    );
  }

  void _onMediaStatusChanged(CastMediaStatus status) {
    _isSyncing = true;
    try {
      // Future position synchronization hooks can be processed here.
    } finally {
      _isSyncing = false;
    }
  }
}
