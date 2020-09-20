import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_clickable_widget.dart';
import 'package:flutter/material.dart';

///Base class for both material and cupertino controls
abstract class BetterPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
  BetterPlayerController getBetterPlayerController();

  void onShowMoreClicked() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          bottom: true,
          child: _buildMoreOptionsList(),
        );
      },
    );
  }

  Widget _buildMoreOptionsList() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            _buildMoreOptionsListRow(Icons.shutter_speed, "Playback speed", () {
              Navigator.of(context).pop();
              _showSpeedChooserWidget();
            })
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionsListRow(IconData icon, String name, Function onTap) {
    return BetterPlayerMaterialClickableWidget(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Text(name),
          ],
        ),
      ),
    );
  }

  void _showSpeedChooserWidget() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSpeedRow(0.25),
                  _buildSpeedRow(0.5),
                  _buildSpeedRow(0.75),
                  _buildSpeedRow(1.0),
                  _buildSpeedRow(1.25),
                  _buildSpeedRow(1.5),
                  _buildSpeedRow(1.75),
                  _buildSpeedRow(2.0),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildSpeedRow(double value) {
    assert(value != null, "Value can't be null");
    return BetterPlayerMaterialClickableWidget(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              "$value x",
              style: TextStyle(
                  fontWeight: getBetterPlayerController()
                              .videoPlayerController
                              .value
                              .speed ==
                          value
                      ? FontWeight.bold
                      : FontWeight.normal),
            )
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        getBetterPlayerController().setSpeed(value);
      },
    );
  }
}
