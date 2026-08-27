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
    classPath: [
      packageRoot.resolve('example/build/better_player_android/tmp/kotlin-classes/debug/'),
      packageRoot.resolve('example/build/better_player_android/intermediates/javac/debug/classes/'),
    ],
    classes: [
      'pl.hasoft.better_player.BetterPlayerApi',
      'pl.hasoft.better_player.BetterPlayerCallback',
      'pl.hasoft.better_player.BetterPlayer',
    ],
  ));
}
