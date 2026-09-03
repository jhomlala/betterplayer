part of '../better_player_controller.dart';

extension PlayerEventsExtension on BetterPlayerController {
  ///Add event listener which listens to player events.
  void addEventsListener(Function(PlayerEvent) eventListener) {
    _eventListeners.add(eventListener);
  }

  ///Remove event listener. This method should be called once you're disposing
  ///Better Player.
  void removeEventsListener(Function(PlayerEvent) eventListener) {
    _eventListeners.remove(eventListener);
  }

  ///Send player event. Shouldn't be used manually.
  void postEvent(PlayerEvent betterPlayerEvent) {
    _postEvent(betterPlayerEvent);
  }

  ///Send player event to all listeners.
  void _postEvent(PlayerEvent betterPlayerEvent) {
    for (final eventListener in _eventListeners) {
      if (eventListener != null) {
        eventListener(betterPlayerEvent);
      }
    }
  }

  /// Add controller internal event.
  void _postControllerEvent(PlayerControllerEvent event) {
    if (!_controllerEventStreamController.isClosed) {
      _controllerEventStreamController.add(event);
    }
  }
}
