import 'package:better_player/src/better_player_event_type.dart';

class BetterPlayerEvent {
  final BetterPlayerEventType betterPlayerEventType;
  final Map<String, dynamic> parameters;

  BetterPlayerEvent(this.betterPlayerEventType, {this.parameters});
}
