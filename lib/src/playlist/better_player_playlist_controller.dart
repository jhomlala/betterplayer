import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_data_source.dart';
import 'package:better_player/src/core/better_player_controller.dart';

class BetterPlayerPlaylistController {
  final List<BetterPlayerDataSource> _betterPlayerDataSourceList;
  final BetterPlayerConfiguration betterPlayerConfiguration;
  final BetterPlayerPlaylistConfiguration betterPlayerPlaylistConfiguration;
  BetterPlayerController _betterPlayerController;
  int _currentDataSourceIndex = 0;
  StreamSubscription _nextVideoTimeStreamSubscription;
  bool _changingToNextVideo = false;

  BetterPlayerPlaylistController(
    this._betterPlayerDataSourceList, {
    this.betterPlayerConfiguration = const BetterPlayerConfiguration(),
    this.betterPlayerPlaylistConfiguration =
        const BetterPlayerPlaylistConfiguration(),
  })  : assert(
            _betterPlayerDataSourceList != null &&
                _betterPlayerDataSourceList.isNotEmpty,
            "Better Player data source list can't be empty"),
        assert(betterPlayerConfiguration != null, "BetterPlayerConfiguration"),
        assert(betterPlayerPlaylistConfiguration != null,
            "BetterPlayerPlaylistConfiguration can't be null") {
    setup();
  }

  void setup() {
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration,
        betterPlayerPlaylistConfiguration: betterPlayerPlaylistConfiguration);
    _currentDataSourceIndex = 0;
    setupDataSource(_currentDataSourceIndex);
    _betterPlayerController.addEventsListener(_handleEvent);
    _nextVideoTimeStreamSubscription = _betterPlayerController
        .nextVideoTimeStreamController.stream
        .listen((data) {
      if (data == 0) {
        _onVideoChange();
      }
    });
  }

  void _onVideoChange() {
    if (_changingToNextVideo) {
      return;
    }
    int nextDataSourceId = _getNextDataSourceIndex();
    if (nextDataSourceId == -1) {
      return;
    }
    if (_betterPlayerController.isFullScreen) {
      _betterPlayerController.exitFullScreen();
    }
    _changingToNextVideo = true;
    setupDataSource(nextDataSourceId);

    _changingToNextVideo = false;
  }

  int get currentDataSourceIndex => _currentDataSourceIndex;

  int get _dataSourceLength => _betterPlayerDataSourceList.length;

  BetterPlayerController get betterPlayerController => _betterPlayerController;

  void _handleEvent(BetterPlayerEvent betterPlayerEvent) {
    if (betterPlayerEvent.betterPlayerEventType ==
        BetterPlayerEventType.finished) {
      _betterPlayerController.startNextVideoTimer();
    }
  }

  void setupDataSource(int index) {
    assert(index != null && index >= 0, "Index must be greater than 0");
    if (index <= _dataSourceLength) {
      _currentDataSourceIndex = index;
      _betterPlayerController
          .setupDataSource(_betterPlayerDataSourceList[index]);
    }
  }

  int _getNextDataSourceIndex() {
    final currentIndex = _currentDataSourceIndex;
    if (currentIndex + 1 <= _currentDataSourceIndex) {
      return currentIndex + 1;
    } else {
      if (betterPlayerPlaylistConfiguration.loopVideos) {
        return 0;
      } else {
        return -1;
      }
    }
  }
}
