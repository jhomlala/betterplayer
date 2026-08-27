import 'dart:io';
import 'package:jnigen/jnigen.dart';

void main(List<String> args) {
  final packageRoot = Platform.script.resolve('../');
  generateJniBindings(Config(
    outputConfig: OutputConfig(
      dartConfig: DartCodeOutputConfig(
        path: packageRoot.resolve('lib/src/better_player_android_jni.g.dart'),
        structure: OutputStructure.singleFile,
      ),
    ),
    androidSdkConfig: AndroidSdkConfig(
      addGradleDeps: true,
      androidExample: 'example', // Points to example app for Gradle resolution
    ),
    sourcePath: [packageRoot.resolve('android/src/main/kotlin/')],
    classes: [
      'pl.hasoft.better_player.BetterPlayerPlugin',
      'pl.hasoft.better_player.BetterPlayer',
      'pl.hasoft.better_player.BetterPlayerCache',
      'pl.hasoft.better_player.CacheDataSourceFactory',
      'pl.hasoft.better_player.CacheWorker',
      'pl.hasoft.better_player.CustomDefaultLoadControl',
      'pl.hasoft.better_player.DataSourceUtils',
      'pl.hasoft.better_player.ImageWorker',
      'pl.hasoft.better_player.QueuingEventSink',
    ],
  ));
}
