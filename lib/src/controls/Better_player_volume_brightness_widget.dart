import 'dart:async';
import 'package:better_player/src/models/show_slider_values.dart';
import 'package:flutter/material.dart';

class VolumeBrightnessWidget extends StatefulWidget {
  final StreamController<double?> value;
  final StreamController<ShowSliderValues?> showSlider;
  const VolumeBrightnessWidget(
      {Key? key, required this.value, required this.showSlider})
      : super(key: key);

  @override
  State<VolumeBrightnessWidget> createState() => _VolumeBrightnessWidgetState();
}

class _VolumeBrightnessWidgetState extends State<VolumeBrightnessWidget> {
  int textValue = 0;
  double sliderValue = 0;
  double value = 0;
  @override
  void initState() {
    super.initState();

    widget.value.stream.listen((event) {
      setState(() {
        value = event ?? 0;
        sliderValue = value / 100;
        textValue = value.toInt();
        print(textValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShowSliderValues?>(
        stream: widget.showSlider.stream,
        builder: (context, snapshot) {
          value = snapshot.data != null ? snapshot.data!.value : 0;
          if (snapshot.hasData) {
            ShowSliderValues data =
                snapshot.data ?? ShowSliderValues(isLeft: true, value: 0);
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Align(
                alignment:
                    data.isLeft ? Alignment.centerLeft : Alignment.centerRight,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${textValue}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontFamily: "teko",
                            fontWeight: FontWeight.w400),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        height: 80,
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            value: sliderValue,
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Icon(
                        data.isLeft ? Icons.volume_up : Icons.brightness_4,
                        color: Colors.white,
                      )
                    ]),
              ),
            );
          } else {
            return Container();
          }
        });
  }
}
