import 'package:better_player/better_player.dart';
import 'package:better_player_example/model/video_list_data.dart';
import 'package:better_player_example/pages/reusable_video_list/reusable_video_list_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReusableVideoListWidget extends StatefulWidget {
  const ReusableVideoListWidget({
    required this.videoListData,
    required this.videoListController,
    super.key,
    this.index = 0,
    this.canBuildVideo,
  });

  final VideoListData videoListData;
  final ReusableVideoListController videoListController;
  final int index;
  final bool Function()? canBuildVideo;

  @override
  State<ReusableVideoListWidget> createState() =>
      _ReusableVideoListWidgetState();
}

class _ReusableVideoListWidgetState extends State<ReusableVideoListWidget> {
  PlayerPoolLease? _lease;
  bool _isLoading = false;

  @override
  void dispose() {
    _releaseLease();
    super.dispose();
  }

  void _releaseLease() {
    if (_lease != null) {
      _lease!.release();
      _lease = null;
    }
  }

  Future<void> _acquireController() async {
    if (_lease != null || _isLoading || !mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final lease = await widget.videoListController.pool.acquire(
        itemId: 'list_item_${widget.index}_${widget.videoListData.videoUrl}',
        index: widget.index,
        dataSource: PlayerDataSource.network(
          widget.videoListData.videoUrl,
          cacheConfiguration: const CacheConfiguration(useCache: true),
        ),
      );

      if (!mounted) {
        lease.release();
        return;
      }

      setState(() {
        _lease = lease;
        _isLoading = false;
      });

      if (widget.videoListData.lastPosition != null) {
        await lease.controller.seekTo(widget.videoListData.lastPosition!);
      }
      if (widget.videoListData.wasPlaying ?? true) {
        await lease.controller.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.videoListData.videoTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          VisibilityDetector(
            key: ValueKey(
              'detector_${widget.index}_${widget.videoListData.videoUrl}',
            ),
            onVisibilityChanged: (info) {
              if (info.visibleFraction >= 0.5) {
                _acquireController();
              } else if (info.visibleFraction < 0.2) {
                if (_lease != null) {
                  widget.videoListData.wasPlaying =
                      _lease?.controller.isPlaying() ?? false;
                  setState(_releaseLease);
                }
              }
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _lease != null
                  ? BetterPlayer(controller: _lease!.controller)
                  : ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white54,
                                size: 48,
                              ),
                      ),
                    ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Recycles controllers across list rows using BetterPlayerPool. '
              'Only rows visible in viewport hold leases; distance-based eviction '
              'safely frees furthest slots.',
            ),
          ),
          Center(
            child: Wrap(
              children: [
                ElevatedButton(
                  child: const Text('Play'),
                  onPressed: () {
                    _lease?.controller.play();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('Pause'),
                  onPressed: () {
                    _lease?.controller.pause();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('Set max volume'),
                  onPressed: () {
                    _lease?.controller.setVolume(1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
