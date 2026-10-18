import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:material_ui/material_ui.dart';

class ControllerControlsPage extends StatefulWidget {
  const ControllerControlsPage({super.key});

  @override
  _ControllerControlsPageState createState() => _ControllerControlsPageState();
}

class _ControllerControlsPageState extends State<ControllerControlsPage> {
  late BetterPlayerController _betterPlayerController;
  final List<_VisibilityLogEntry> _visibilityLogs = [];
  StreamSubscription<bool>? _visibilitySubscription;

  @override
  void initState() {
    super.initState();
    const betterPlayerConfiguration = PlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    final dataSource = PlayerDataSource(
      DataSourceType.network,
      Constants.elephantDreamVideoUrl,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);

    _visibilitySubscription = _betterPlayerController.controlsVisibilityStream
        .listen((isVisible) {
          if (mounted) {
            setState(() {
              _visibilityLogs.insert(
                0,
                _VisibilityLogEntry(
                  timestamp: DateTime.now(),
                  isVisible: isVisible,
                ),
              );
            });
          }
        });
  }

  @override
  void dispose() {
    _visibilitySubscription?.cancel();
    _betterPlayerController.dispose();
    super.dispose();
  }

  void _clearLogs() {
    setState(_visibilityLogs.clear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programmatic Controls'),
        actions: [
          IconButton(
            tooltip: 'Clear event log',
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: DemoContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoHeader(
                title: 'External Controller API',
                description:
                    'Drive playback programmatically via BetterPlayerController '
                    'methods and monitor overlay visibility changes.',
                instructions:
                    'Click buttons below, tap the video screen, or wait for the auto-hide timer '
                    'to see controlsVisibilityStream update in real time.',
                icon: Icons.tune_outlined,
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController),
              ),
              const SizedBox(height: 16),
              _ControlsActionButtons(controller: _betterPlayerController),
              const SizedBox(height: 16),
              _ControlsVisibilityStatusCard(
                controller: _betterPlayerController,
              ),
              const SizedBox(height: 16),
              _ControlsVisibilityLogView(
                logs: _visibilityLogs,
                onClear: _clearLogs,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlsActionButtons extends StatelessWidget {
  const _ControlsActionButtons({
    required this.controller,
  });

  final BetterPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: controller.play,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
          FilledButton.tonalIcon(
            onPressed: controller.pause,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              controller.setControlsVisibility(false);
            },
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Hide Controls'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              controller.setControlsVisibility(true);
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Show Controls'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              controller.setControlsVisibility(!controller.isControlsVisible);
            },
            icon: const Icon(Icons.swap_horiz_outlined),
            label: const Text('Toggle Controls'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              controller.setControlsEnabled(!controller.controlsEnabled);
            },
            icon: Icon(
              controller.controlsEnabled
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
            ),
            label: Text(
              controller.controlsEnabled
                  ? 'Disable Controls'
                  : 'Enable Controls',
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsVisibilityStatusCard extends StatelessWidget {
  const _ControlsVisibilityStatusCard({
    required this.controller,
  });

  final BetterPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<bool>(
        stream: controller.controlsVisibilityStream,
        initialData: controller.isControlsVisible,
        builder: (context, snapshot) {
          final isVisible = snapshot.data ?? false;
          final colorScheme = theme.colorScheme;
          final statusColor = isVisible ? Colors.green : Colors.grey;

          return Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isVisible
                        ? Icons.visibility
                        : Icons.visibility_off_outlined,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'controlsVisibilityStream',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVisible ? 'Controls Visible' : 'Controls Hidden',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isVisible ? Colors.green : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: CircleAvatar(
                          backgroundColor: controller.controlsEnabled
                              ? Colors.green
                              : Colors.red,
                          radius: 5,
                        ),
                        label: Text(
                          'enabled: ${controller.controlsEnabled}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Chip(
                        avatar: CircleAvatar(
                          backgroundColor: statusColor,
                          radius: 5,
                        ),
                        label: Text(
                          'isControlsVisible: $isVisible',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ControlsVisibilityLogView extends StatelessWidget {
  const _ControlsVisibilityLogView({
    required this.logs,
    required this.onClear,
  });

  final List<_VisibilityLogEntry> logs;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stream Event Log (${logs.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (logs.isNotEmpty)
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No events emitted yet. Interact with the video or controls.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 10 ? 10 : logs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = logs[index];
                final time =
                    '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${entry.timestamp.second.toString().padLeft(2, '0')}.'
                    '${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    entry.isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: entry.isVisible ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  title: Text(
                    entry.isVisible
                        ? 'controlsVisibilityStream: true'
                        : 'controlsVisibilityStream: false',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: entry.isVisible ? Colors.green : null,
                    ),
                  ),
                  trailing: Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VisibilityLogEntry {
  const _VisibilityLogEntry({
    required this.timestamp,
    required this.isVisible,
  });

  final DateTime timestamp;
  final bool isVisible;
}
