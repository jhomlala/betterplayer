import 'dart:async';
import 'package:flutter/material.dart';

class SeekToViewMaterialWidget extends StatefulWidget {
  final StreamController<int?> value;
  const SeekToViewMaterialWidget({Key? key, required this.value})
      : super(key: key);

  @override
  State<SeekToViewMaterialWidget> createState() =>
      _SeekToViewMaterialWidgetState();
}

class _SeekToViewMaterialWidgetState extends State<SeekToViewMaterialWidget> {
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
                child: formatDigitalClock(
                    Duration(milliseconds: snapshot.data ?? 0).inSeconds),
                // Text(
                //   "${formatDigitalClock(Duration(milliseconds: snapshot.data ?? 0).inSeconds)}",
                //   style: TextStyle(
                //       fontSize: 40,
                //       color: const Color.fromARGB(255, 242, 242, 242),
                //       fontFamily: "teko",
                //       fontWeight: FontWeight.w600),
                // ),
              ),
            );
          } else {
            return Container();
          }
        });
  }

  // String formatDigitalClock(int seconds) {
  //   int hours = seconds ~/ 3600;
  //   int remainingMinutes = (seconds % 3600) ~/ 60;
  //   int remainingSeconds = seconds % 60;
  //   String formattedHours = hours.toString().padLeft(2, '0');
  //   String formattedMinutes = remainingMinutes.toString().padLeft(2, '0');
  //   String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');
  //   if (seconds < 3600) {
  //     return "${formattedMinutes}:${formattedSeconds}";
  //   }
  //   return "$formattedHours:$formattedMinutes:$formattedSeconds";
  // }

  Widget formatDigitalClock(int seconds) {
    int hours = seconds ~/ 3600;
    int remainingMinutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    String formattedHours = hours.toString().padLeft(2, '0');
    String formattedMinutes = remainingMinutes.toString().padLeft(2, '0');
    String formattedSeconds = remainingSeconds.toString().padLeft(2, '0');
    // if (seconds < 3600) {
    //   return "${formattedMinutes}:${formattedSeconds}";
    // }
    // return "$formattedHours:$formattedMinutes:$formattedSeconds";
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (seconds > 3600) clockValue(formattedHours),
        if (seconds > 3600) clockValueIndicator("H "),
        if (seconds > 3600) clockValue(": "),
        clockValue(formattedMinutes),
        clockValueIndicator("M "),
        clockValue(": ${formattedSeconds}"),
        clockValueIndicator("S "),
      ],
    );
  }

  Text clockValue(String value) {
    return Text(
      value,
      style: TextStyle(
          fontSize: 40,
          color: const Color.fromARGB(255, 242, 242, 242),
          fontFamily: "teko",
          fontWeight: FontWeight.w600),
    );
  }

  Text clockValueIndicator(String value) {
    return Text(
      value,
      style: TextStyle(
          fontSize: 10,
          color: Colors.white54,
          fontFamily: "teko",
          fontWeight: FontWeight.w500),
    );
  }
}
