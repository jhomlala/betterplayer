import 'package:better_player/better_player.dart';
import 'package:better_player/src/controls/better_player_selection_list_item_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/better_player_mock_controller.dart';
import '../helpers/mock_player_engine_controller.dart';

class BetterPlayerMockControllerWithTracks extends BetterPlayerMockController {
  BetterPlayerMockControllerWithTracks(super.betterPlayerConfiguration);

  List<PlayerAsmsTrack> _tracks = [];
  PlayerDataSource? _dataSource;

  @override
  List<PlayerAsmsTrack> get betterPlayerAsmsTracks => _tracks;

  @override
  PlayerDataSource? get betterPlayerDataSource => _dataSource;

  void setTracks(List<PlayerAsmsTrack> tracks) {
    _tracks = tracks;
  }

  void setDataSource(PlayerDataSource dataSource) {
    _dataSource = dataSource;
  }
}

class MockControlsWidget extends StatefulWidget {
  const MockControlsWidget({
    required this.controller,
    super.key,
  });
  final BetterPlayerController controller;

  @override
  MockControlsState createState() => MockControlsState();
}

class MockControlsState extends BetterPlayerControlsState<MockControlsWidget> {
  @override
  BetterPlayerController? get betterPlayerController => widget.controller;

  @override
  PlayerControlsConfiguration get betterPlayerControlsConfiguration =>
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
        const PlayerConfiguration(),
      );
      controller.engineController = MockPlayerEngineController();
    });

    testWidgets(
      'Auto track has correct semantics identifier when fields are 0',
      (tester) async {
        controller.setTracks([
          PlayerAsmsTrack.defaultTrack(), // 0, 0, 0
          PlayerAsmsTrack('', 1920, 1080, 5000000, 30, '', ''),
        ]);
        controller.setDataSource(PlayerDataSource.network('url.m3u8'));

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: false),
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
      (tester) async {
        controller.setTracks([
          PlayerAsmsTrack('', null, null, null, null, '', ''),
        ]);
        controller.setDataSource(PlayerDataSource.network('url.m3u8'));

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: false),
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
      tester,
    ) async {
      controller.setTracks([
        PlayerAsmsTrack.defaultTrack(),
        PlayerAsmsTrack('', 1920, 1080, 5000000, 30, '', ''),
      ]);
      controller.setDataSource(PlayerDataSource.network('url.m3u8'));

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

    testWidgets(
      'Non-ASMS (normal MP4) resolution has quality_auto identifier when children empty',
      (tester) async {
        controller.setTracks([]);
        controller.setDataSource(PlayerDataSource.network('video.mp4'));

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: false),
            home: MockControlsWidget(controller: controller),
          ),
        );

        final state = tester.state<MockControlsState>(
          find.byType(MockControlsWidget),
        );

        state.showQualities();
        await tester.pumpAndSettle();

        // For normal MP4 without multiple resolutions, the fallback is "Auto"
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
      'Non-ASMS (normal MP4) with multiple resolutions has index-based semantics identifier',
      (tester) async {
        controller.setTracks([]);
        controller.setDataSource(
          PlayerDataSource.network(
            'video.mp4',
            qualities: {
              'LOW': 'low.mp4',
              'HIGH': 'high.mp4',
            },
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: false),
            home: MockControlsWidget(controller: controller),
          ),
        );

        final state = tester.state<MockControlsState>(
          find.byType(MockControlsWidget),
        );

        state.showQualities();
        await tester.pumpAndSettle();

        // Find the "LOW" item (index 0)
        final lowItem = find.byWidgetPredicate(
          (widget) =>
              widget is BetterPlayerSelectionListItemWidget &&
              widget.label == 'LOW',
        );

        expect(lowItem, findsOneWidget);

        final lowWidget = tester.widget<BetterPlayerSelectionListItemWidget>(
          lowItem,
        );
        expect(
          lowWidget.semanticsIdentifier,
          'better_player_overflow_menu_quality_0',
        );

        // Find the "HIGH" item (index 1)
        final highItem = find.byWidgetPredicate(
          (widget) =>
              widget is BetterPlayerSelectionListItemWidget &&
              widget.label == 'HIGH',
        );

        expect(highItem, findsOneWidget);

        final highWidget = tester.widget<BetterPlayerSelectionListItemWidget>(
          highItem,
        );
        expect(
          highWidget.semanticsIdentifier,
          'better_player_overflow_menu_quality_1',
        );
      },
    );
  });
}
