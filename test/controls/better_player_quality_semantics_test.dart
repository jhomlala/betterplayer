import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_controls_state.dart';
import 'package:better_player/src/controls/better_player_selection_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/mock_video_player_controller.dart';

class BetterPlayerMockControllerWithTracks extends BetterPlayerMockController {
  BetterPlayerMockControllerWithTracks(super.betterPlayerConfiguration);

  List<BetterPlayerAsmsTrack> _tracks = [];
  BetterPlayerDataSource? _dataSource;

  @override
  List<BetterPlayerAsmsTrack> get betterPlayerAsmsTracks => _tracks;

  @override
  BetterPlayerDataSource? get betterPlayerDataSource => _dataSource;

  void setTracks(List<BetterPlayerAsmsTrack> tracks) {
    _tracks = tracks;
  }

  void setDataSource(BetterPlayerDataSource dataSource) {
    _dataSource = dataSource;
  }
}

class MockControlsWidget extends StatefulWidget {
  final BetterPlayerController controller;

  const MockControlsWidget({
    required this.controller,
    super.key,
  });

  @override
  MockControlsState createState() => MockControlsState();
}

class MockControlsState extends BetterPlayerControlsState<MockControlsWidget> {
  @override
  BetterPlayerController? get betterPlayerController => widget.controller;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      widget.controller.betterPlayerControlsConfiguration;

  @override
  VideoPlayerValue? get latestValue =>
      widget.controller.videoPlayerController?.value;

  @override
  void cancelAndRestartTimer() {}

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  void showQualities() {
    showQualitiesSelectionWidget();
  }
}

void main() {
  group('BetterPlayerControlsState Quality Semantics Tests', () {
    late BetterPlayerMockControllerWithTracks controller;

    setUp(() {
      controller = BetterPlayerMockControllerWithTracks(
        const BetterPlayerConfiguration(),
      );
      controller.videoPlayerController = MockVideoPlayerController();
    });

    testWidgets(
      'Auto track has correct semantics identifier when fields are 0',
      (WidgetTester tester) async {
        controller.setTracks([
          BetterPlayerAsmsTrack.defaultTrack(), // 0, 0, 0
          BetterPlayerAsmsTrack('', 1920, 1080, 5000000, 30, '', ''),
        ]);
        controller.setDataSource(BetterPlayerDataSource.network('url.m3u8'));

        await tester.pumpWidget(
          MaterialApp(
            home: MockControlsWidget(controller: controller),
          ),
        );

        final state = tester.state<MockControlsState>(
          find.byType(MockControlsWidget),
        );

        // Open qualities menu
        state.showQualities();
        await tester.pumpAndSettle();

        // Find the "Auto" item
        final autoItem = find.byWidgetPredicate(
          (widget) =>
              widget is BetterPlayerSelectionListItemWidget &&
              widget.label == controller.translations.qualityAuto,
        );

        expect(autoItem, findsOneWidget);

        final widget = tester.widget<BetterPlayerSelectionListItemWidget>(
          autoItem,
        );
        expect(
          widget.semanticsIdentifier,
          'better_player_overflow_menu_quality_auto',
        );
      },
    );

    testWidgets(
      'Auto track has correct semantics identifier when fields are null',
      (WidgetTester tester) async {
        controller.setTracks([
          BetterPlayerAsmsTrack('', null, null, null, null, '', ''),
        ]);
        controller.setDataSource(BetterPlayerDataSource.network('url.m3u8'));

        await tester.pumpWidget(
          MaterialApp(
            home: MockControlsWidget(controller: controller),
          ),
        );

        final state = tester.state<MockControlsState>(
          find.byType(MockControlsWidget),
        );

        state.showQualities();
        await tester.pumpAndSettle();

        final autoItem = find.byWidgetPredicate(
          (widget) =>
              widget is BetterPlayerSelectionListItemWidget &&
              widget.label == controller.translations.qualityAuto,
        );

        expect(autoItem, findsOneWidget);

        final widget = tester.widget<BetterPlayerSelectionListItemWidget>(
          autoItem,
        );
        expect(
          widget.semanticsIdentifier,
          'better_player_overflow_menu_quality_auto',
        );
      },
    );

    testWidgets('Non-auto track has index-based semantics identifier', (
      WidgetTester tester,
    ) async {
      controller.setTracks([
        BetterPlayerAsmsTrack.defaultTrack(),
        BetterPlayerAsmsTrack('', 1920, 1080, 5000000, 30, '', ''),
      ]);
      controller.setDataSource(BetterPlayerDataSource.network('url.m3u8'));

      await tester.pumpWidget(
        MaterialApp(
          home: MockControlsWidget(controller: controller),
        ),
      );

      final state = tester.state<MockControlsState>(
        find.byType(MockControlsWidget),
      );

      state.showQualities();
      await tester.pumpAndSettle();

      // Find the 1080p item (index 1)
      final trackItem = find.byWidgetPredicate(
        (widget) =>
            widget is BetterPlayerSelectionListItemWidget &&
            widget.label.contains('1920x1080'),
      );

      expect(trackItem, findsOneWidget);

      final widget = tester.widget<BetterPlayerSelectionListItemWidget>(
        trackItem,
      );
      expect(
        widget.semanticsIdentifier,
        'better_player_overflow_menu_quality_1',
      );
    });
  });
}
