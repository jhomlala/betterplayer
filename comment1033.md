You can build whatever layout you need (lock buttons, cast buttons, etc.) by passing your own widget to `customControlsBuilder` and setting the theme to `PlayerTheme.custom`.

This replaces the default controls entirely, letting you place your buttons anywhere above the video. Better Player passes you the controller, and you wire up the UI.

Check out `example/lib/pages/custom_controls/custom_controls_widget.dart` in this repository for a working example of how to hook it up.
