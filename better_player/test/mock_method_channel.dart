import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockMethodChannel {
  final MethodChannel channel = const MethodChannel("better_player_channel");
  final List<MethodChannel> eventsChannels = [];

  Future<Object?>? handle(MethodCall methodCall) async {
    if (methodCall.method == "create") {
      final int id = getNextId();
      _createEventChannel(id);
      return _getCreateResult(id);
    }
    if (methodCall.method == "setDataSource") {
      //return
    }
    return <String, String>{};
  }

  int getNextId() {
    return eventsChannels.length;
  }

  Map<String, dynamic> _getCreateResult(int id) =>
      <String, dynamic>{"textureId": id};

  Map<String, dynamic> _getInitResult() => <String, dynamic>{
        "event": "initialized",
        "height": 720.0,
        "width:": 1280.0,
        "duration": 100
      };

  void _createEventChannel(int id) {
    final MethodChannel eventChannel =
        MethodChannel("better_player_channel/videoEvents$id");
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, (MethodCall methodCall) async {
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .handlePlatformMessage(
              "better_player_channel/videoEvents$id",
              const StandardMethodCodec()
                  .encodeSuccessEnvelope(_getInitResult()),
              (ByteData? data) {});
      return null;
    });

    eventsChannels.add(eventChannel);
  }
}
