import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../utils.dart';

class ClearKeyPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ClearKeyState();
}

class _ClearKeyState extends State<ClearKeyPage> {
  late BetterPlayerController _clearKeyControllerFile;
  late BetterPlayerController _clearKeyControllerBroken;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    _clearKeyControllerFile = BetterPlayerController(betterPlayerConfiguration);
    _clearKeyControllerBroken =
        BetterPlayerController(betterPlayerConfiguration);

    _setupDataSources();

    super.initState();
  }

  void _setupDataSources() async {
    BetterPlayerDataSource _clearKeyDataSourceFile = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        await Utils.getFileUrl(Constants.fileTestVideoEncryptUrl),
        // videoFormat: BetterPlayerVideoFormat.hls,
        drmConfiguration: BetterPlayerDrmConfiguration(
            drmType: BetterPlayerDrmType.clearKey,
            clearKey: BetterPlayerClearKeyUtils.generate({
              "f3c5e0361e6654b28f8049c778b23946":
                  "a4631a153a443df9eed0593043db7519",
              "abba271e8bcf552bbd2e86a434a9a5d9":
                  "69eaa802a6763af979e8d1940fb88392"
            })));

    _clearKeyControllerFile.setupDataSource(_clearKeyDataSourceFile);

//providing an invalid key
    BetterPlayerDataSource _clearKeyDataSourceBroken = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        await Utils.getFileUrl(Constants.fileTestVideoEncryptUrl),
        // videoFormat: BetterPlayerVideoFormat.hls,
        drmConfiguration: BetterPlayerDrmConfiguration(
            drmType: BetterPlayerDrmType.clearKey,
            clearKey: BetterPlayerClearKeyUtils.generate({
              "f3c5e0361e6654b28f8049c778b23946":
                  "a4631a153a443df9eed0593043d11111",
              "abba271e8bcf552bbd2e86a434a9a5d9":
                  "69eaa802a6763af979e8d1940fb11111"
            })));

    _clearKeyControllerBroken.setupDataSource(_clearKeyDataSourceBroken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ClearKey player"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "ClearKey Protection  with valid key.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _clearKeyControllerFile),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "ClearKey Protection Asset with invalid key.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _clearKeyControllerBroken),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
