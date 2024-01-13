import 'dart:async';
import 'package:flutter/material.dart';

class SeekToViewWidget extends StatefulWidget {
  final StreamController<int?> value;
  const SeekToViewWidget({Key? key, required this.value}) : super(key: key);

  @override
  State<SeekToViewWidget> createState() => _SeekToViewWidgetState();
}

class _SeekToViewWidgetState extends State<SeekToViewWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
        stream: widget.value.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "${formatDigitalClock(Duration(milliseconds: snapshot.data ?? 0).inSeconds)}",
                  style: TextStyle(
                      fontSize: 40,
                      color: const Color.fromARGB(255, 242, 242, 242),
                      fontFamily: "teko",
                      fontWeight: FontWeight.w600),
                ),
              ),
            );
          } else {
            return Container();
          }
        });
  }

  String formatDigitalClock(int seconds) {
    int hours = seconds ~/ 3600;
    int remainingMinutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    String formattedHours = hours.toString().padLeft(2, '0');
    String formattedMinutes = remainingMinutes.toString().padLeft(2, '0');
    String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');

    return "$formattedHours:$formattedMinutes:$formattedSeconds";
  }
}
