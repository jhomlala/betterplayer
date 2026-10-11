import 'package:better_player/better_player.dart';
import 'package:better_player_example/constants.dart';
import 'package:better_player_example/utils.dart';
import 'package:better_player_example/widgets/demo_container.dart';
import 'package:better_player_example/widgets/demo_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  _PlaylistPageState() {
    _betterPlayerConfiguration = const PlayerConfiguration(
      aspectRatio: 1,
      fit: BoxFit.cover,
      showPlaceholderUntilPlay: true,
      subtitlesConfiguration: PlayerSubtitlesConfiguration(fontSize: 10),
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
    _betterPlayerPlaylistConfiguration = const PlayerPlaylistConfiguration();
  }

  final GlobalKey<BetterPlayerPlaylistState> _betterPlayerPlaylistStateKey =
      GlobalKey();
  final List<PlayerDataSource> _dataSourceList = [];
  late PlayerConfiguration _betterPlayerConfiguration;
  late PlayerPlaylistConfiguration _betterPlayerPlaylistConfiguration;

  Future<List<PlayerDataSource>> setupData() async {
    _dataSourceList.add(
      PlayerDataSource(
        DataSourceType.network,
        Constants.bugBuckBunnyVideoUrl,
        subtitles: kIsWeb
            ? PlayerSubtitlesSource.single(
                type: PlayerSubtitlesSourceType.memory,
                content: await rootBundle.loadString(
                  'assets/example_subtitles.srt',
                ),
              )
            : PlayerSubtitlesSource.single(
                type: PlayerSubtitlesSourceType.file,
                url: await Utils.getFileUrl(Constants.fileExampleSubtitlesUrl),
              ),
        placeholder: Image.network(Constants.catImageUrl, fit: BoxFit.cover),
      ),
    );

    _dataSourceList.add(
      PlayerDataSource(
        DataSourceType.network,
        Constants.forBiggerBlazesUrl,
        placeholder: Image.network(Constants.catImageUrl, fit: BoxFit.cover),
      ),
    );
    _dataSourceList.add(
      PlayerDataSource(
        DataSourceType.network,
        Constants.forBiggerJoyridesVideoUrl,
      ),
    );

    return _dataSourceList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      body: FutureBuilder<List<PlayerDataSource>>(
        future: setupData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return SingleChildScrollView(
              child: DemoContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DemoHeader(
                      title: 'Continuous Video Queue',
                      description:
                          'Advances to next video automatically upon completion. '
                          'Controls are locked during track transition.',
                      instructions:
                          'Use the action buttons below to test programmatic queue jumps.',
                      icon: Icons.playlist_play_outlined,
                    ),
                    AspectRatio(
                      aspectRatio: 1,
                      child: BetterPlayerPlaylist(
                        key: _betterPlayerPlaylistStateKey,
                        betterPlayerConfiguration: _betterPlayerConfiguration,
                        betterPlayerPlaylistConfiguration:
                            _betterPlayerPlaylistConfiguration,
                        betterPlayerDataSourceList: snapshot.data!,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: () {
                              _betterPlayerPlaylistController
                                  ?.playPreviousVideo();
                            },
                            label: const Text('Previous Video'),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.skip_next),
                            onPressed: () {
                              _betterPlayerPlaylistController?.playNextVideo();
                            },
                            label: const Text('Next Video'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.first_page),
                            onPressed: () {
                              _betterPlayerPlaylistController?.setupDataSource(
                                0,
                              );
                            },
                            label: const Text('Jump to First (0)'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.last_page),
                            onPressed: () {
                              _betterPlayerPlaylistController?.setupDataSource(
                                2,
                              );
                            },
                            label: const Text('Jump to Last (2)'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.pause),
                            onPressed: () {
                              _betterPlayerPlaylistController
                                  ?.betterPlayerController
                                  ?.pause();
                            },
                            label: const Text('Pause'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              final list = [
                                PlayerDataSource(
                                  DataSourceType.network,
                                  Constants.bugBuckBunnyVideoUrl,
                                  placeholder: Image.network(
                                    Constants.catImageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ];
                              _betterPlayerPlaylistController
                                  ?.setupDataSourceList(
                                    list,
                                  );
                            },
                            label: const Text('Reset Queue List'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  BetterPlayerPlaylistController? get _betterPlayerPlaylistController =>
      _betterPlayerPlaylistStateKey
          .currentState!
          .betterPlayerPlaylistController;
}
