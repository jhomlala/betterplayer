import 'package:flutter/services.dart';

class MockMethodChannel {
  final MethodChannel channel = MethodChannel("better_player_channel");

  final List<MethodChannel> eventsChannels = List();



  MockMethodChannel() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      print("Method: " + methodCall.method + " args: " + methodCall.arguments.toString());
      if (methodCall.method == "create") {
        int id = getNextId();
        _createEventChannel(id);
        return _getCreateResult(id);

      }
      if (methodCall.method == "setDataSource") {
        return null;
      }
      return Map<String, String>();
    });

  }

  int getNextId(){
    return eventsChannels.length;
  }

  Map<String, dynamic> _getCreateResult(int id) => <String, dynamic>{"textureId": id};

  Map<String, dynamic> _getInitResult() => <String, dynamic>{
        "event": "initialized",
        "height": 720.0,
        "width:": 1280.0,
        "duration": 100
      };

  void _createEventChannel(int id){
    final MethodChannel eventChannel =
    MethodChannel("better_player_channel/videoEvents${id}");

    eventChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
          "better_player_channel/videoEvents${id}",
          const StandardMethodCodec().encodeSuccessEnvelope(_getInitResult()),
              (ByteData data) {});
    });

    eventsChannels.add(eventChannel);
  }
}
