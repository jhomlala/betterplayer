import 'package:better_player/better_player.dart';
import 'package:better_player_tizen/better_player_tizen.dart';
import 'package:better_player_tizen_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Renders Tizen example app and player tree', (tester) async {
    BetterPlayerTizen.registerWith();
    await tester.pumpWidget(const BetterPlayerTizenExampleApp());
    await tester.pump();
    expect(find.byType(TizenVideoPlayerScreen), findsOneWidget);
    expect(find.byType(BetterPlayer), findsOneWidget);
  });
}
