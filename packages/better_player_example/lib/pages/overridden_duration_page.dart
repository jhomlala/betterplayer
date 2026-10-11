import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class OverriddenDurationPage extends StatefulWidget {
  const OverriddenDurationPage({super.key});

  @override
  _OverriddenDurationPageState createState() => _OverriddenDurationPageState();
}

class _OverriddenDurationPageState extends State<OverriddenDurationPage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _setupDataSource();
    super.initState();
  }

  Future<void> _setupDataSource() async {
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
      overriddenDuration: const Duration(seconds: 10),
    );
    _betterPlayerController.setupDataSource(dataSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overridden Duration')),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'Custom Total Duration Limit',
                description:
                    'Truncates or extends reported total duration (capped to 10 seconds '
                    'in this sample) without altering native source files.',
                instructions:
                    'Observe timeline seeker max limit fixed at 00:10.',
                icon: Icons.timelapse_outlined,
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
