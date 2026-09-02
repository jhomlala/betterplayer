import 'package:better_player/src/configuration/player_event_type.dart';

///Event that happens in player. It can be used to determine current player state
///on higher layer.
class PlayerEvent {
  PlayerEvent(this.betterPlayerEventType, {this.parameters});
  final PlayerEventType betterPlayerEventType;
  final Map<String, dynamic>? parameters;
}
