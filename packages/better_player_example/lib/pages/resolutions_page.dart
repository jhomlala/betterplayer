import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class ResolutionsPage extends StatefulWidget {
  const ResolutionsPage({super.key});

  @override
  _ResolutionsPageState createState() => _ResolutionsPageState();
}

class _ResolutionsPageState extends State<ResolutionsPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.exampleResolutionsUrls.values.first,
      resolutions: Constants.exampleResolutionsUrls,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resolution Switching')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Manual Resolution Selection',
                description:
                    'Configures multiple video resolution URLs for non-HLS streams '
                    'allowing manual quality picking in the player overflow menu.',
                instructions:
                    'Open the player menu (three dots) > Quality to switch video resolution.',
                icon: Icons.high_quality_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
